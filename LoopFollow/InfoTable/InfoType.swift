// LoopFollow
// InfoType.swift
// Created by Jonas Björkert.

import Foundation

enum InfoType: Int, CaseIterable {
    case iob, cob, basal, override, battery, pump, sage, cage, recBolus, minMax, carbsToday, autosens, profile, target, isf, carbRatio, updated, tdd, iage

    var name: String {
        switch self {
        case .iob: return "IOB"
        case .cob: return "COB"
        case .basal: return "Basal"
        case .override: return "Overstyring"
        case .battery: return "Batteri"
        case .pump: return "Pumpe"
        case .sage: return "SAGE"
        case .cage: return "CAGE"
        case .recBolus: return "Anbefalt bolus"
        case .minMax: return "Min/Max"
        case .carbsToday: return "Karbo i dag"
        case .autosens: return "Autosens"
        case .profile: return "Profil"
        case .target: return "Target"
        case .isf: return "ISF"
        case .carbRatio: return "CR"
        case .updated: return "Oppdatert"
        case .tdd: return "TDD"
        case .iage: return "IAGE"
        }
    }

    var defaultVisible: Bool {
        switch self {
        case .iob, .cob, .basal, .override, .battery, .pump, .sage, .cage, .recBolus, .minMax, .carbsToday:
            return true
        default:
            return false
        }
    }

    var sortOrder: Int {
        return rawValue
    }
}
