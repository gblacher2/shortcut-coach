import Foundation

public enum BaseCatalogSource: Sendable {
    case bundled
    case data(Data)
    case url(URL)
}

public enum EnvironmentCatalogSource: Sendable {
    case bundled
    case missing
    case data(Data)
    case url(URL)
}

public struct CatalogLoader: Sendable {
    public init() {}

    /// Production loads use both bundled resources. Tests can explicitly inject
    /// valid, missing, or malformed environment data without modifying the bundle.
    public func load(
        base source: BaseCatalogSource = .bundled,
        environment environmentSource: EnvironmentCatalogSource = .bundled
    ) throws -> LoadedCatalog {
        let baseCatalog = try decodeBaseCatalog(from: baseCatalogData(for: source))
        try validateBaseCatalog(baseCatalog)

        switch environmentData(for: environmentSource) {
        case .missing:
            return loadedCatalog(base: baseCatalog, environment: nil, state: .missing)
        case let .rejected(reason):
            return loadedCatalog(base: baseCatalog, environment: nil, state: .rejected(reason: reason))
        case let .data(data):
            do {
                let environment = try JSONDecoder().decode(EnvironmentCatalog.self, from: data)
                try environment.validate()
                try validateNoCrossCatalogIDCollisions(environment: environment, base: baseCatalog)
                return loadedCatalog(base: baseCatalog, environment: environment, state: .loaded)
            } catch {
                return loadedCatalog(
                    base: baseCatalog,
                    environment: nil,
                    state: .rejected(reason: environmentRejectionReason(for: error))
                )
            }
        }
    }

    /// Compatibility for callers that already inject concrete data. Unlike the
    /// previous optional API, a missing overlay is represented explicitly with
    /// `EnvironmentCatalogSource.missing`.
    public func load(environmentData: Data) throws -> LoadedCatalog {
        try load(environment: .data(environmentData))
    }

    public func bundledEnvironmentData() throws -> Data {
        guard let url = packagedOrModuleResourceURL(
            forResource: "my-mac-environment",
            withExtension: "json"
        ) else {
            throw EnvironmentResourceError.missing
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw EnvironmentResourceError.unreadable
        }
    }

    private func baseCatalogData(for source: BaseCatalogSource) throws -> Data {
        switch source {
        case .bundled:
            guard let url = packagedOrModuleResourceURL(
                forResource: "mac-shortcuts",
                withExtension: "json"
            ) else {
                throw CatalogError.missingCatalog
            }
            do {
                return try Data(contentsOf: url)
            } catch {
                throw CatalogError.invalidCatalog(reason: "The bundled data could not be read.")
            }
        case let .data(data):
            return data
        case let .url(url):
            do {
                return try Data(contentsOf: url)
            } catch {
                throw CatalogError.invalidCatalog(reason: "The supplied base catalog could not be read.")
            }
        }
    }

    private func packagedOrModuleResourceURL(
        forResource name: String,
        withExtension extensionName: String
    ) -> URL? {
        if let resourcesURL = Bundle.main.resourceURL {
            let bundleURL = resourcesURL.appendingPathComponent(
                "ShortcutCoach_ShortcutCoachCore.bundle",
                isDirectory: true
            )
            if let packagedBundle = Bundle(url: bundleURL),
               let packagedURL = packagedBundle.url(forResource: name, withExtension: extensionName) {
                return packagedURL
            }
        }
        return Bundle.module.url(forResource: name, withExtension: extensionName)
    }

    private func decodeBaseCatalog(from data: Data) throws -> ShortcutCatalog {
        do {
            return try JSONDecoder().decode(ShortcutCatalog.self, from: data)
        } catch let DecodingError.dataCorrupted(context) {
            throw CatalogError.invalidCatalog(reason: "Data corrupted: \(context.debugDescription)")
        } catch let DecodingError.keyNotFound(key, context) {
            throw CatalogError.invalidCatalog(
                reason: "Required key '\(key.stringValue)' is missing at \(codingPathDescription(context.codingPath))."
            )
        } catch let DecodingError.valueNotFound(_, context) {
            throw CatalogError.invalidCatalog(
                reason: "A required value is missing at \(codingPathDescription(context.codingPath))."
            )
        } catch let DecodingError.typeMismatch(_, context) {
            throw CatalogError.invalidCatalog(
                reason: "A value has the wrong type at \(codingPathDescription(context.codingPath))."
            )
        } catch {
            throw CatalogError.invalidCatalog(reason: error.localizedDescription)
        }
    }

    private func validateBaseCatalog(_ catalog: ShortcutCatalog) throws {
        guard catalog.schemaVersion == 1 else {
            throw CatalogError.invalidCatalog(reason: "Unsupported schema version \(catalog.schemaVersion).")
        }
        guard !catalog.catalogVersion.isBlank else {
            throw CatalogError.invalidCatalog(reason: "catalogVersion must not be blank.")
        }
        guard !catalog.publishedAt.isBlank else {
            throw CatalogError.invalidCatalog(reason: "publishedAt must not be blank.")
        }
        guard !catalog.validatedMacOSVersion.isBlank else {
            throw CatalogError.invalidCatalog(reason: "validatedMacOSVersion must not be blank.")
        }

        guard catalog.apps.count == 9 else {
            throw CatalogError.invalidCatalog(reason: "Catalog schema v1 requires exactly nine supported apps.")
        }
        let appIDs = catalog.apps.map(\.id)
        guard Set(appIDs).count == appIDs.count else {
            throw CatalogError.invalidCatalog(reason: "Duplicate supported-app IDs are not allowed.")
        }
        let expectedAppIDs = Set(SupportedApp.launchApps.map(\.id))
        guard Set(appIDs) == expectedAppIDs else {
            throw CatalogError.invalidCatalog(reason: "Supported-app IDs do not match the schema v1 launch set.")
        }
        for app in catalog.apps {
            guard !app.id.isBlank, !app.name.isBlank, !app.symbolName.isBlank else {
                throw CatalogError.invalidCatalog(reason: "Supported-app identity fields must not be blank.")
            }
            guard app.aliases.allSatisfy({ !$0.isBlank }) else {
                throw CatalogError.invalidCatalog(reason: "Supported-app aliases must not be blank.")
            }
        }

        guard catalog.shortcuts.count == 56 else {
            throw CatalogError.invalidCatalog(reason: "Catalog schema v1 requires exactly 56 immutable shortcuts.")
        }
        let shortcutIDs = catalog.shortcuts.map(\.id)
        guard Set(shortcutIDs).count == shortcutIDs.count else {
            throw CatalogError.invalidCatalog(reason: "Duplicate shortcut IDs are not allowed.")
        }
        let validShortcutIDs = Set(shortcutIDs)

        for appID in expectedAppIDs {
            let count = catalog.shortcuts.count(where: { $0.appID == appID })
            guard (5...8).contains(count) else {
                throw CatalogError.invalidCatalog(
                    reason: "App '\(appID)' must have between five and eight curated shortcuts."
                )
            }
        }

        for shortcut in catalog.shortcuts {
            guard
                !shortcut.id.isBlank,
                !shortcut.title.isBlank,
                !shortcut.category.isBlank,
                !shortcut.guidance.isBlank,
                !shortcut.displayText.isBlank
            else {
                throw CatalogError.invalidCatalog(reason: "Shortcut '\(shortcut.id)' has blank required text.")
            }
            guard expectedAppIDs.contains(shortcut.appID) else {
                throw CatalogError.invalidCatalog(
                    reason: "Shortcut '\(shortcut.id)' references unsupported app '\(shortcut.appID)'."
                )
            }
            guard !shortcut.keys.isEmpty, shortcut.keys.allSatisfy({ !$0.isBlank }) else {
                throw CatalogError.invalidCatalog(reason: "Shortcut '\(shortcut.id)' has invalid ordered keys.")
            }
            guard shortcut.displayText == shortcut.keys.joined(separator: " + ") else {
                throw CatalogError.invalidCatalog(
                    reason: "Shortcut '\(shortcut.id)' display text does not match its ordered keys."
                )
            }
            guard shortcut.taskTags.allSatisfy({ !$0.isBlank }) else {
                throw CatalogError.invalidCatalog(reason: "Shortcut '\(shortcut.id)' has a blank task tag.")
            }
            if let menuPath = shortcut.menuPath {
                guard !menuPath.isEmpty, menuPath.allSatisfy({ !$0.isBlank }) else {
                    throw CatalogError.invalidCatalog(reason: "Shortcut '\(shortcut.id)' has an invalid menu path.")
                }
            }
            guard !shortcut.relatedIDs.contains(shortcut.id) else {
                throw CatalogError.invalidCatalog(reason: "Shortcut '\(shortcut.id)' cannot relate to itself.")
            }
            for relatedID in shortcut.relatedIDs where !validShortcutIDs.contains(relatedID) {
                throw CatalogError.invalidCatalog(
                    reason: "Shortcut '\(shortcut.id)' references missing related shortcut '\(relatedID)'."
                )
            }

            guard !shortcut.sourceReference.title.isBlank else {
                throw CatalogError.invalidCatalog(reason: "Shortcut '\(shortcut.id)' has a blank source title.")
            }
            switch shortcut.sourceReference.kind {
            case .officialDocumentation:
                guard
                    let rawURL = shortcut.sourceReference.url,
                    let url = URL(string: rawURL),
                    url.scheme?.lowercased() == "https",
                    url.host != nil
                else {
                    throw CatalogError.invalidCatalog(
                        reason: "Shortcut '\(shortcut.id)' official source must be a valid HTTPS URL."
                    )
                }
            case .installedAppMenu:
                guard shortcut.appID == "antigravity" || shortcut.appID == "whatsapp" else {
                    throw CatalogError.invalidCatalog(
                        reason: "Installed-menu evidence is only valid for the locally inspected apps."
                    )
                }
            case .localConfiguration, .systemPreference, .toolConfiguration:
                throw CatalogError.invalidCatalog(
                    reason: "Shortcut '\(shortcut.id)' uses environment evidence in the immutable app catalog."
                )
            }

            guard
                !shortcut.validation.macOSVersion.isBlank,
                !shortcut.validation.verifiedAt.isBlank,
                !shortcut.validation.method.isBlank
            else {
                throw CatalogError.invalidCatalog(reason: "Shortcut '\(shortcut.id)' has incomplete validation metadata.")
            }
            if let appVersion = shortcut.validation.appVersion, appVersion.isBlank {
                throw CatalogError.invalidCatalog(reason: "Shortcut '\(shortcut.id)' has a blank app version.")
            }
            if let caveat = shortcut.caveat, caveat.isBlank {
                throw CatalogError.invalidCatalog(reason: "Shortcut '\(shortcut.id)' has a blank caveat.")
            }
        }
    }

    private func environmentData(for source: EnvironmentCatalogSource) -> EnvironmentDataResolution {
        switch source {
        case .missing:
            return .missing
        case let .data(data):
            return .data(data)
        case let .url(url):
            do {
                return .data(try Data(contentsOf: url))
            } catch {
                return .rejected(reason: "The My Mac shortcut data could not be read.")
            }
        case .bundled:
            do {
                return .data(try bundledEnvironmentData())
            } catch EnvironmentResourceError.missing {
                return .missing
            } catch {
                return .rejected(reason: "The bundled My Mac shortcut data could not be read.")
            }
        }
    }

    private func validateNoCrossCatalogIDCollisions(
        environment: EnvironmentCatalog,
        base: ShortcutCatalog
    ) throws {
        let baseIDs = Set(base.shortcuts.map(\.id))
        let collisions = Set(environment.bindings.map(\.id)).intersection(baseIDs).sorted()
        guard collisions.isEmpty else {
            throw EnvironmentCatalogValidationError.invalid(
                "Environment binding IDs collide with immutable catalog IDs: \(collisions.joined(separator: ", "))."
            )
        }
    }

    private func loadedCatalog(
        base: ShortcutCatalog,
        environment: EnvironmentCatalog?,
        state: EnvironmentState
    ) -> LoadedCatalog {
        guard let environment else {
            return LoadedCatalog(
                catalog: base,
                sourceDescription: "Built-in catalog v\(base.catalogVersion)",
                environmentState: state,
                environmentCatalog: nil,
                environmentConflictsByID: [:],
                environmentConflictsByBindingID: [:]
            )
        }

        let conflictByID = Dictionary(uniqueKeysWithValues: environment.conflicts.map { ($0.id, $0) })
        var conflictsByBindingID: [String: [EnvironmentConflict]] = [:]
        for binding in environment.bindings {
            conflictsByBindingID[binding.id] = binding.conflictIDs.compactMap { conflictByID[$0] }
        }

        let environmentEntries = environment.bindings
            .filter(\.enabled)
            .map { binding in
                makeCatalogEntry(
                    from: binding,
                    environment: environment,
                    classification: environment.recommendedShortcutCoachChanges.classification(for: binding.id)
                )
            }

        let mergedCatalog = ShortcutCatalog(
            schemaVersion: base.schemaVersion,
            catalogVersion: base.catalogVersion,
            publishedAt: base.publishedAt,
            validatedMacOSVersion: base.validatedMacOSVersion,
            apps: base.apps,
            shortcuts: base.shortcuts + environmentEntries
        )

        return LoadedCatalog(
            catalog: mergedCatalog,
            sourceDescription: "Built-in catalog v\(base.catalogVersion) + My Mac",
            environmentState: state,
            environmentCatalog: environment,
            environmentConflictsByID: conflictByID,
            environmentConflictsByBindingID: conflictsByBindingID
        )
    }

    private func makeCatalogEntry(
        from binding: EnvironmentBinding,
        environment: EnvironmentCatalog,
        classification: EnvironmentClassification?
    ) -> ShortcutCatalogEntry {
        let sourceReference: SourceReference
        switch binding.sourceType {
        case .officialDocumentation:
            sourceReference = SourceReference(
                title: "Apple Support — \(binding.action)",
                url: binding.source,
                kind: .officialDocumentation
            )
        case .systemPreference:
            sourceReference = SourceReference(title: binding.source, kind: .systemPreference)
        case .toolConfiguration:
            sourceReference = SourceReference(title: binding.source, kind: .toolConfiguration)
        }

        let stability: EntryStability = binding.caveat == nil ? .stable : .contextual

        return ShortcutCatalogEntry(
            id: binding.id,
            appID: "my-mac",
            title: binding.action,
            keys: binding.keys,
            displayText: binding.displayText,
            taskTags: [],
            category: binding.category,
            guidance: practicalGuidance(for: binding),
            sourceReference: sourceReference,
            validation: ValidationMetadata(
                macOSVersion: environment.macOSVersion,
                verifiedAt: environment.generatedAt,
                method: binding.sourceType.rawValue
            ),
            stability: stability,
            caveat: binding.caveat,
            owner: binding.owner,
            conflictIDs: binding.conflictIDs,
            defaultStatus: binding.defaultStatus.rawValue,
            environmentClassification: classification,
            environmentConfidence: binding.confidence.rawValue,
            outputSummary: binding.output.summary,
            outputType: binding.output.type.rawValue,
            outputKeys: binding.output.keys,
            environmentScope: binding.scope.rawValue
        )
    }

    private func practicalGuidance(for binding: EnvironmentBinding) -> String {
        let action = binding.action.prefix(1).lowercased() + binding.action.dropFirst()
        switch binding.category {
        case "text-editing":
            return "Use this while editing text when you want to \(action) without leaving the keyboard."
        case "window-management":
            return "Use this while arranging your workspace when you want to \(action)."
        case "spaces", "mission-control":
            return "Use this while navigating your workspace when you want to \(action)."
        case "input-sources":
            return "Use this when changing keyboard input and you want to \(action)."
        default:
            return "Use this when you want to \(action) quickly."
        }
    }

    private func environmentRejectionReason(for error: Error) -> String {
        if let validationError = error as? EnvironmentCatalogValidationError {
            return validationError.localizedDescription
        }
        if error is DecodingError {
            return "The My Mac shortcut data is malformed or does not match environment schema v1."
        }
        return "The My Mac shortcut data was rejected because it could not be validated."
    }
}

private enum EnvironmentDataResolution {
    case data(Data)
    case missing
    case rejected(reason: String)
}

public enum EnvironmentState: Equatable, Sendable {
    case loaded
    case missing
    case rejected(reason: String)
}

public struct LoadedCatalog: Sendable {
    public let catalog: ShortcutCatalog
    public let sourceDescription: String
    public let environmentState: EnvironmentState
    public let environmentCatalog: EnvironmentCatalog?
    public let environmentConflictsByID: [String: EnvironmentConflict]
    public let environmentConflictsByBindingID: [String: [EnvironmentConflict]]
}

public enum EnvironmentResourceError: LocalizedError, Sendable {
    case missing
    case unreadable

    public var errorDescription: String? {
        switch self {
        case .missing: "The bundled My Mac shortcut data is missing."
        case .unreadable: "The bundled My Mac shortcut data could not be read."
        }
    }
}

public enum CatalogError: LocalizedError, Sendable {
    case missingCatalog
    case invalidCatalog(reason: String)

    public var errorDescription: String? {
        switch self {
        case .missingCatalog: "The immutable built-in shortcut catalog is missing."
        case let .invalidCatalog(reason): "The built-in shortcut catalog is invalid: \(reason)"
        }
    }
}

private func codingPathDescription(_ path: [CodingKey]) -> String {
    let description = path.map(\.stringValue).joined(separator: ".")
    return description.isEmpty ? "the catalog root" : description
}

private extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
