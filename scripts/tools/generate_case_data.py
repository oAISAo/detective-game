#!/usr/bin/env python3
"""Generate all JSON data files for The Riverside Apartment Murder case.
Based on the case specification in Detective Investigation Game.md (lines 1253-1671).

Run from project root:
    python3 scripts/tools/generate_case_data.py
"""
import json
import os

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "data", "cases", "riverside_apartment")

def write_json(filename, data):
    path = os.path.join(OUTPUT_DIR, filename)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent="\t", ensure_ascii=False)
        f.write("\n")
    print(f"  Written: {filename}")


# =========================================================================
# case.json
# =========================================================================
CASE = {
    "id": "riverside_apartment",
    "title": "The Riverside Apartment Murder",
    "description": "Daniel Ross, a 42-year-old financial consultant, is found dead in his apartment from a knife wound. Estimated time of death: 21:00. As the lead detective, you have four days to investigate the crime scene, interrogate suspects, analyze evidence, and build a case for the prosecutor.",
    "start_day": 1,
    "end_day": 4,
    "solution": {
        "suspect": "p_julia",
        "motive": "Daniel discovered Mark was stealing money and planned to expose him. Julia learned about it and feared financial ruin. She killed Daniel during a confrontation.",
        "weapon": "Kitchen knife",
        "time_minutes": 1260,
        "time_day": 1,
        "access": "Julia was Daniel's wife and had access to the apartment"
    },
    "critical_evidence_ids": [
        "ev_julia_fingerprint_glass",
        "ev_elevator_logs",
        "ev_shoe_print",
        "ev_personal_journal"
    ]
}


# =========================================================================
# suspects.json
# =========================================================================
SUSPECTS = {
    "persons": [
        {
            "id": "p_victim",
            "name": "Daniel Ross",
            "role": "VICTIM",
            "personality_traits": [],
            "relationships": [
                {"person_b": "p_mark", "type": "BUSINESS_PARTNER"},
                {"person_b": "p_julia", "type": "SPOUSE"}
            ],
            "pressure_threshold": 0
        },
        {
            "id": "p_mark",
            "name": "Mark Bennett",
            "role": "SUSPECT",
            "personality_traits": ["ANXIOUS"],
            "relationships": [
                {"person_b": "p_victim", "type": "BUSINESS_PARTNER"}
            ],
            "pressure_threshold": 4
        },
        {
            "id": "p_sarah",
            "name": "Sarah Klein",
            "role": "SUSPECT",
            "personality_traits": ["CALM"],
            "relationships": [
                {"person_b": "p_victim", "type": "FRIEND"}
            ],
            "pressure_threshold": 3
        },
        {
            "id": "p_julia",
            "name": "Julia Ross",
            "role": "SUSPECT",
            "personality_traits": ["AGGRESSIVE", "MANIPULATIVE"],
            "relationships": [
                {"person_b": "p_victim", "type": "SPOUSE"},
                {"person_b": "p_mark", "type": "FRIEND"}
            ],
            "pressure_threshold": 6
        },
        {
            "id": "p_lucas",
            "name": "Lucas Weber",
            "role": "SUSPECT",
            "personality_traits": ["CALM"],
            "relationships": [],
            "pressure_threshold": 2
        }
    ]
}


# =========================================================================
# locations.json
# =========================================================================
LOCATIONS = {
    "locations": [
        {
            "id": "loc_victim_apartment",
            "name": "Victim's Apartment",
            "description": "Daniel Ross's apartment where his body was found. The crime scene. Contains the kitchen, living room, and personal belongings.",
            "searchable": True,
            "investigable_objects": [
                {
                    "id": "obj_kitchen",
                    "name": "Kitchen",
                    "description": "The kitchen area. A knife block sits on the counter with one knife missing. The murder weapon was found in the kitchen sink.",
                    "available_actions": ["visual_inspection"],
                    "tool_requirements": [],
                    "evidence_results": ["ev_knife", "ev_knife_block"],
                    "investigation_state": "NOT_INSPECTED"
                },
                {
                    "id": "obj_living_room",
                    "name": "Living Room",
                    "description": "The main living area. Two wine glasses sit on the table beside an open wine bottle. A broken picture frame lies on the floor.",
                    "available_actions": ["visual_inspection", "fingerprint_analysis"],
                    "tool_requirements": ["fingerprint_powder"],
                    "evidence_results": ["ev_wine_glasses", "ev_broken_picture_frame", "ev_wine_bottle"],
                    "investigation_state": "NOT_INSPECTED"
                },
                {
                    "id": "obj_victim_phone",
                    "name": "Victim's Phone",
                    "description": "Daniel's phone found on the table. Contains messages and call logs.",
                    "available_actions": ["examine_device"],
                    "tool_requirements": [],
                    "evidence_results": ["ev_victim_phone", "ev_julia_text_message", "ev_mark_call_log"],
                    "investigation_state": "NOT_INSPECTED"
                }
            ],
            "evidence_pool": [
                "ev_knife", "ev_wine_glasses", "ev_julia_fingerprint_glass",
                "ev_mark_fingerprint_desk", "ev_broken_picture_frame",
                "ev_victim_phone", "ev_julia_text_message", "ev_mark_call_log",
                "ev_wine_bottle", "ev_knife_block"
            ]
        },
        {
            "id": "loc_hallway",
            "name": "Building Hallway",
            "description": "The hallway of the apartment building. Security cameras and elevator access logs are available here.",
            "searchable": True,
            "investigable_objects": [
                {
                    "id": "obj_hallway_floor",
                    "name": "Hallway Floor",
                    "description": "The hallway floor near the apartment entrance. Forensic examination may reveal traces.",
                    "available_actions": ["visual_inspection", "fingerprint_analysis"],
                    "tool_requirements": ["forensic_kit"],
                    "evidence_results": ["ev_shoe_print"],
                    "investigation_state": "NOT_INSPECTED"
                },
                {
                    "id": "obj_security_system",
                    "name": "Building Security System",
                    "description": "Security camera recordings and elevator access logs for the building.",
                    "available_actions": ["examine_device"],
                    "tool_requirements": [],
                    "evidence_results": ["ev_hallway_camera", "ev_elevator_logs"],
                    "investigation_state": "NOT_INSPECTED"
                },
                {
                    "id": "obj_maintenance_office",
                    "name": "Maintenance Office",
                    "description": "The building maintenance office. Work logs and key records are kept here.",
                    "available_actions": ["visual_inspection"],
                    "tool_requirements": [],
                    "evidence_results": ["ev_lucas_work_log"],
                    "investigation_state": "NOT_INSPECTED"
                }
            ],
            "evidence_pool": [
                "ev_hallway_camera", "ev_elevator_logs",
                "ev_shoe_print", "ev_lucas_work_log"
            ]
        },
        {
            "id": "loc_parking_lot",
            "name": "Parking Lot",
            "description": "The parking lot adjacent to the apartment building. A security camera covers the entrance and exit.",
            "searchable": True,
            "investigable_objects": [
                {
                    "id": "obj_parking_camera",
                    "name": "Parking Lot Security Camera",
                    "description": "A security camera that records vehicles and people entering and leaving the parking area.",
                    "available_actions": ["examine_device"],
                    "tool_requirements": [],
                    "evidence_results": ["ev_parking_camera"],
                    "investigation_state": "NOT_INSPECTED"
                }
            ],
            "evidence_pool": ["ev_parking_camera"]
        },
        {
            "id": "loc_neighbor_apartment",
            "name": "Neighbor's Apartment",
            "description": "Sarah Klein's apartment, located next door to the victim. Sarah is the victim's neighbor and a potential witness.",
            "searchable": False,
            "investigable_objects": [
                {
                    "id": "obj_sarah_interview",
                    "name": "Interview Sarah Klein",
                    "description": "Talk to Sarah Klein about what she heard on the night of the murder.",
                    "available_actions": ["visual_inspection"],
                    "tool_requirements": [],
                    "evidence_results": ["ev_sarah_testimony"],
                    "investigation_state": "NOT_INSPECTED"
                }
            ],
            "evidence_pool": ["ev_sarah_testimony", "ev_sarah_second_testimony"]
        },
        {
            "id": "loc_victim_office",
            "name": "Victim's Office",
            "description": "Daniel Ross's office at his financial consulting firm. Contains business records, personal files, and a hidden safe.",
            "searchable": True,
            "investigable_objects": [
                {
                    "id": "obj_office_desk",
                    "name": "Office Desk",
                    "description": "A heavy oak desk with multiple drawers. One appears locked.",
                    "available_actions": ["visual_inspection", "examine_device"],
                    "tool_requirements": [],
                    "evidence_results": ["ev_daniel_email"],
                    "investigation_state": "NOT_INSPECTED"
                },
                {
                    "id": "obj_file_cabinet",
                    "name": "File Cabinet",
                    "description": "A locked file cabinet containing financial documents and client records.",
                    "available_actions": ["visual_inspection"],
                    "tool_requirements": [],
                    "evidence_results": ["ev_bank_transfer", "ev_accounting_files"],
                    "investigation_state": "NOT_INSPECTED"
                },
                {
                    "id": "obj_office_safe",
                    "name": "Hidden Safe",
                    "description": "A safe concealed behind a bookshelf. Contains confidential documents about the embezzlement.",
                    "available_actions": ["visual_inspection"],
                    "tool_requirements": [],
                    "evidence_results": ["ev_hidden_safe"],
                    "investigation_state": "NOT_INSPECTED"
                },
                {
                    "id": "obj_personal_items",
                    "name": "Personal Items",
                    "description": "Daniel's personal belongings at the office, including a journal.",
                    "available_actions": ["visual_inspection"],
                    "tool_requirements": [],
                    "evidence_results": ["ev_personal_journal"],
                    "investigation_state": "NOT_INSPECTED"
                }
            ],
            "evidence_pool": [
                "ev_daniel_email", "ev_bank_transfer", "ev_accounting_files",
                "ev_hidden_safe", "ev_personal_journal"
            ]
        }
    ]
}


# =========================================================================
# evidence.json — 25 evidence items (E1-E25)
# =========================================================================
EVIDENCE = {
    "evidence": [
        # E1 — Murder Weapon (Kitchen Knife)
        {
            "id": "ev_knife",
            "name": "Murder Weapon (Kitchen Knife)",
            "description": "A bloody kitchen knife found in the victim's kitchen sink. Blood matches the victim.",
            "type": "FORENSIC",
            "location_found": "loc_victim_apartment",
            "related_persons": ["p_victim"],
            "weight": 0.9,
            "importance_level": "CRITICAL",
            "discovery_method": "VISUAL",
            "legal_categories": ["CONNECTION"]
        },
        # E2 — Two Wine Glasses
        {
            "id": "ev_wine_glasses",
            "name": "Two Wine Glasses on Table",
            "description": "Two wine glasses on the living room table. Indicates the victim had company before the murder.",
            "type": "OBJECT",
            "location_found": "loc_victim_apartment",
            "related_persons": [],
            "weight": 0.5,
            "importance_level": "SUPPORTING",
            "discovery_method": "VISUAL",
            "legal_categories": ["PRESENCE"]
        },
        # E3 — Julia's Fingerprint on Wine Glass (Lab result Day 2)
        {
            "id": "ev_julia_fingerprint_glass",
            "name": "Julia's Fingerprint on Wine Glass",
            "description": "Fingerprint analysis of the wine glass reveals Julia Ross's fingerprints. Contradicts her statement that she was not at the apartment that night.",
            "type": "FORENSIC",
            "location_found": "loc_victim_apartment",
            "related_persons": ["p_julia"],
            "weight": 0.9,
            "importance_level": "CRITICAL",
            "discovery_method": "LAB",
            "requires_lab_analysis": True,
            "lab_result_text": "Fingerprint matched to Julia Ross. Clear ridge patterns confirm identity.",
            "legal_categories": ["PRESENCE", "CONNECTION"],
            "hint_text": "Have the wine glasses analyzed for fingerprints at the lab."
        },
        # E4 — Mark's Fingerprint on Desk
        {
            "id": "ev_mark_fingerprint_desk",
            "name": "Mark's Fingerprint on Desk",
            "description": "Fingerprint analysis of the victim's desk reveals Mark Bennett's prints. Confirms his earlier visit.",
            "type": "FORENSIC",
            "location_found": "loc_victim_apartment",
            "related_persons": ["p_mark"],
            "weight": 0.4,
            "importance_level": "SUPPORTING",
            "discovery_method": "LAB",
            "requires_lab_analysis": True,
            "lab_result_text": "Fingerprint matched to Mark Bennett.",
            "legal_categories": ["PRESENCE"]
        },
        # E5 — Broken Picture Frame
        {
            "id": "ev_broken_picture_frame",
            "name": "Broken Picture Frame",
            "description": "A broken picture frame on the floor. The photo shows Daniel and Julia together. Suggests an argument took place.",
            "type": "OBJECT",
            "location_found": "loc_victim_apartment",
            "related_persons": ["p_victim", "p_julia"],
            "weight": 0.4,
            "importance_level": "SUPPORTING",
            "discovery_method": "VISUAL",
            "legal_categories": ["CONNECTION"]
        },
        # E6 — Victim's Phone
        {
            "id": "ev_victim_phone",
            "name": "Victim's Phone",
            "description": "Daniel's phone found on the table. Contains messages and call history.",
            "type": "OBJECT",
            "location_found": "loc_victim_apartment",
            "related_persons": ["p_victim"],
            "weight": 0.5,
            "importance_level": "SUPPORTING",
            "discovery_method": "VISUAL",
            "legal_categories": []
        },
        # E7 — Text Message From Julia (20:40)
        {
            "id": "ev_julia_text_message",
            "name": "Text Message From Julia",
            "description": "A text message from Julia to Daniel at 20:40: \"Are you home? We need to talk.\"",
            "type": "DIGITAL",
            "location_found": "loc_victim_apartment",
            "related_persons": ["p_julia", "p_victim"],
            "weight": 0.6,
            "importance_level": "SUPPORTING",
            "discovery_method": "VISUAL",
            "legal_categories": ["PRESENCE", "CONNECTION"],
            "hint_text": "Check the victim's phone for recent messages."
        },
        # E8 — Deleted Messages (Recovered Later, warrant needed)
        {
            "id": "ev_deleted_messages",
            "name": "Deleted Messages (Recovered)",
            "description": "Recovered deleted messages between Daniel and Julia showing a heated argument about money. Unlocked via phone search warrant.",
            "type": "DIGITAL",
            "location_found": "",
            "related_persons": ["p_victim", "p_julia"],
            "weight": 0.7,
            "importance_level": "CRITICAL",
            "discovery_method": "TOOL",
            "legal_categories": ["MOTIVE", "CONNECTION"],
            "hint_text": "A warrant to search Julia's phone may reveal deleted messages."
        },
        # E9 — Call Log Between Mark and Daniel
        {
            "id": "ev_mark_call_log",
            "name": "Call Log Between Mark and Daniel",
            "description": "Phone call log showing multiple calls between Mark and Daniel about financial issues in the days before the murder.",
            "type": "DIGITAL",
            "location_found": "loc_victim_apartment",
            "related_persons": ["p_mark", "p_victim"],
            "weight": 0.5,
            "importance_level": "SUPPORTING",
            "discovery_method": "VISUAL",
            "legal_categories": ["MOTIVE", "CONNECTION"]
        },
        # E10 — Email From Daniel to Mark
        {
            "id": "ev_daniel_email",
            "name": "Email From Daniel to Mark",
            "description": "An email from Daniel to Mark. Subject: \"We need to fix this before tomorrow.\" References financial irregularities.",
            "type": "DIGITAL",
            "location_found": "loc_victim_office",
            "related_persons": ["p_victim", "p_mark"],
            "weight": 0.6,
            "importance_level": "SUPPORTING",
            "discovery_method": "VISUAL",
            "legal_categories": ["MOTIVE", "CONNECTION"]
        },
        # E11 — Suspicious Bank Transfer
        {
            "id": "ev_bank_transfer",
            "name": "Suspicious Bank Transfer",
            "description": "Records showing money moved from the company account to an unknown destination. Suggests embezzlement.",
            "type": "FINANCIAL",
            "location_found": "loc_victim_office",
            "related_persons": ["p_mark"],
            "weight": 0.8,
            "importance_level": "CRITICAL",
            "discovery_method": "VISUAL",
            "legal_categories": ["MOTIVE"],
            "hint_text": "Check the file cabinet in Daniel's office for financial records."
        },
        # E12 — Accounting Files
        {
            "id": "ev_accounting_files",
            "name": "Accounting Files",
            "description": "Detailed accounting files showing a pattern of embezzlement from the company. Found in the victim's office.",
            "type": "FINANCIAL",
            "location_found": "loc_victim_office",
            "related_persons": ["p_mark", "p_victim"],
            "weight": 0.7,
            "importance_level": "SUPPORTING",
            "discovery_method": "VISUAL",
            "legal_categories": ["MOTIVE"]
        },
        # E13 — Julia's Financial Records
        {
            "id": "ev_julia_financial_records",
            "name": "Julia's Financial Records",
            "description": "Julia's personal financial records showing large debts. Provides additional financial motive.",
            "type": "FINANCIAL",
            "location_found": "",
            "related_persons": ["p_julia"],
            "weight": 0.5,
            "importance_level": "SUPPORTING",
            "discovery_method": "VISUAL",
            "legal_categories": ["MOTIVE"]
        },
        # E14 — Parking Lot Camera
        {
            "id": "ev_parking_camera",
            "name": "Parking Lot Camera Footage",
            "description": "Security camera footage from the parking lot showing Mark Bennett leaving the building at 20:40.",
            "type": "RECORDING",
            "location_found": "loc_parking_lot",
            "related_persons": ["p_mark"],
            "weight": 0.7,
            "importance_level": "CRITICAL",
            "discovery_method": "VISUAL",
            "legal_categories": ["PRESENCE"],
            "hint_text": "Check the security camera in the parking lot."
        },
        # E15 — Hallway Camera (Blurry Figure)
        {
            "id": "ev_hallway_camera",
            "name": "Hallway Camera (Blurry Figure)",
            "description": "Security camera footage showing someone entering the apartment at approximately 20:50. The figure's height roughly matches Julia Ross.",
            "type": "RECORDING",
            "location_found": "loc_hallway",
            "related_persons": ["p_julia"],
            "weight": 0.6,
            "importance_level": "SUPPORTING",
            "discovery_method": "VISUAL",
            "legal_categories": ["PRESENCE"]
        },
        # E16 — Elevator Logs
        {
            "id": "ev_elevator_logs",
            "name": "Elevator Logs",
            "description": "Building elevator access logs showing Julia Ross's key card was used at 20:48 on the night of the murder.",
            "type": "DOCUMENT",
            "location_found": "loc_hallway",
            "related_persons": ["p_julia"],
            "weight": 0.8,
            "importance_level": "CRITICAL",
            "discovery_method": "VISUAL",
            "legal_categories": ["PRESENCE", "OPPORTUNITY"],
            "hint_text": "Check the building's elevator access records."
        },
        # E17 — Sarah's Testimony
        {
            "id": "ev_sarah_testimony",
            "name": "Sarah's Testimony",
            "description": "Sarah Klein's initial statement: she heard an argument around 20:45 but claims she did not see anyone in the hallway.",
            "type": "DOCUMENT",
            "location_found": "loc_neighbor_apartment",
            "related_persons": ["p_sarah"],
            "weight": 0.5,
            "importance_level": "SUPPORTING",
            "discovery_method": "VISUAL",
            "legal_categories": []
        },
        # E18 — Sarah's Second Testimony
        {
            "id": "ev_sarah_second_testimony",
            "name": "Sarah's Second Testimony",
            "description": "Under pressure, Sarah admits hearing a female voice during the argument. She also remembers hearing quick footsteps in the hallway.",
            "type": "DOCUMENT",
            "location_found": "loc_neighbor_apartment",
            "related_persons": ["p_sarah"],
            "weight": 0.6,
            "importance_level": "SUPPORTING",
            "discovery_method": "VISUAL",
            "legal_categories": ["CONNECTION"]
        },
        # E19 — Lucas Work Log
        {
            "id": "ev_lucas_work_log",
            "name": "Lucas Work Log",
            "description": "Maintenance work log showing Lucas Weber was working until 20:00, contradicting his claim of finishing at 19:00. However, he was in a different part of the building.",
            "type": "DOCUMENT",
            "location_found": "loc_hallway",
            "related_persons": ["p_lucas"],
            "weight": 0.3,
            "importance_level": "SUPPORTING",
            "discovery_method": "VISUAL",
            "legal_categories": ["PRESENCE"]
        },
        # E20 — Shoe Print in Hallway
        {
            "id": "ev_shoe_print",
            "name": "Shoe Print in Hallway",
            "description": "A shoe print found in the hallway near the victim's apartment. Lab analysis matches Julia Ross's shoes.",
            "type": "FORENSIC",
            "location_found": "loc_hallway",
            "related_persons": ["p_julia"],
            "weight": 0.8,
            "importance_level": "CRITICAL",
            "discovery_method": "TOOL",
            "requires_lab_analysis": True,
            "lab_result_text": "Shoe print pattern matches a pair of women's shoes, size 38. Consistent with Julia Ross's shoe size.",
            "legal_categories": ["PRESENCE"],
            "hint_text": "Examine the hallway floor for footprints."
        },
        # E21 — Julia's Shoes (Search Warrant)
        {
            "id": "ev_julia_shoes",
            "name": "Julia's Shoes (Search Warrant)",
            "description": "Julia's shoes obtained via search warrant. The soles match the hallway shoe print exactly.",
            "type": "OBJECT",
            "location_found": "",
            "related_persons": ["p_julia"],
            "weight": 0.8,
            "importance_level": "CRITICAL",
            "discovery_method": "VISUAL",
            "legal_categories": ["PRESENCE", "CONNECTION"],
            "hint_text": "A search warrant for Julia's residence may yield matching shoes."
        },
        # E22 — Wine Bottle
        {
            "id": "ev_wine_bottle",
            "name": "Wine Bottle",
            "description": "A recently opened bottle of wine on the table. Confirms the victim was sharing drinks with someone.",
            "type": "OBJECT",
            "location_found": "loc_victim_apartment",
            "related_persons": [],
            "weight": 0.2,
            "importance_level": "OPTIONAL",
            "discovery_method": "VISUAL",
            "legal_categories": []
        },
        # E23 — Knife Block in Kitchen
        {
            "id": "ev_knife_block",
            "name": "Knife Block in Kitchen",
            "description": "A knife block on the kitchen counter with one knife missing. The missing knife matches the murder weapon.",
            "type": "OBJECT",
            "location_found": "loc_victim_apartment",
            "related_persons": [],
            "weight": 0.3,
            "importance_level": "SUPPORTING",
            "discovery_method": "VISUAL",
            "legal_categories": []
        },
        # E24 — Hidden Safe in Office
        {
            "id": "ev_hidden_safe",
            "name": "Hidden Safe in Office",
            "description": "A hidden safe found in Daniel's office containing documents about the embezzlement scheme. Reveals the full extent of Mark's financial crimes and Daniel's plan to expose him.",
            "type": "DOCUMENT",
            "location_found": "loc_victim_office",
            "related_persons": ["p_mark", "p_victim"],
            "weight": 0.85,
            "importance_level": "CRITICAL",
            "discovery_method": "VISUAL",
            "legal_categories": ["MOTIVE"],
            "hint_text": "Look carefully around Daniel's office — there may be hidden compartments."
        },
        # E25 — Daniel's Personal Journal
        {
            "id": "ev_personal_journal",
            "name": "Daniel's Personal Journal",
            "description": "Daniel's personal journal found in his office. Recent entries mention confronting both Mark about the embezzlement and Julia about their marriage. The last entry reads: \"I have to tell Julia everything tomorrow.\"",
            "type": "DOCUMENT",
            "location_found": "loc_victim_office",
            "related_persons": ["p_victim", "p_mark", "p_julia"],
            "weight": 0.85,
            "importance_level": "CRITICAL",
            "discovery_method": "VISUAL",
            "legal_categories": ["MOTIVE", "CONNECTION"],
            "hint_text": "Daniel may have kept personal notes at his office."
        }
    ]
}


# =========================================================================
# timeline.json
# =========================================================================
TIMELINE = {
    "events": [
        # Event 1 — Mark Arrives (19:30)
        {
            "id": "evt_mark_arrives",
            "description": "Mark Bennett visits Daniel Ross at his apartment.",
            "time": "19:30",
            "day": 1,
            "location": "loc_victim_apartment",
            "involved_persons": ["p_mark", "p_victim"],
            "supporting_evidence": ["ev_mark_fingerprint_desk"],
            "certainty_level": "CONFIRMED"
        },
        # Event 2 — Argument About Money (20:15)
        {
            "id": "evt_argument_money",
            "description": "Daniel confronts Mark about financial irregularities and the embezzlement.",
            "time": "20:15",
            "day": 1,
            "location": "loc_victim_apartment",
            "involved_persons": ["p_mark", "p_victim"],
            "supporting_evidence": ["ev_daniel_email", "ev_bank_transfer"],
            "certainty_level": "LIKELY"
        },
        # Event 3 — Mark Leaves (20:40)
        {
            "id": "evt_mark_leaves",
            "description": "Mark Bennett exits the building. Captured on parking lot security camera.",
            "time": "20:40",
            "day": 1,
            "location": "loc_parking_lot",
            "involved_persons": ["p_mark"],
            "supporting_evidence": ["ev_parking_camera"],
            "certainty_level": "CONFIRMED"
        },
        # Event 4 — Julia Sends Text (20:40)
        {
            "id": "evt_julia_text",
            "description": "Julia Ross sends a text message to Daniel: \"Are you home? We need to talk.\"",
            "time": "20:40",
            "day": 1,
            "location": "",
            "involved_persons": ["p_julia"],
            "supporting_evidence": ["ev_julia_text_message"],
            "certainty_level": "CONFIRMED"
        },
        # Event 5 — Julia Arrives (20:50)
        {
            "id": "evt_julia_arrives",
            "description": "Julia Ross enters the apartment building. Captured on hallway camera and elevator logs.",
            "time": "20:50",
            "day": 1,
            "location": "loc_hallway",
            "involved_persons": ["p_julia"],
            "supporting_evidence": ["ev_elevator_logs", "ev_hallway_camera"],
            "certainty_level": "CONFIRMED"
        },
        # Event 6 — Loud Argument (20:55)
        {
            "id": "evt_loud_argument",
            "description": "Sarah Klein hears loud shouting from Daniel's apartment.",
            "time": "20:55",
            "day": 1,
            "location": "loc_victim_apartment",
            "involved_persons": ["p_victim", "p_julia"],
            "supporting_evidence": ["ev_sarah_testimony"],
            "certainty_level": "CLAIMED"
        },
        # Event 7 — Murder (21:00)
        {
            "id": "evt_murder",
            "description": "Daniel Ross is stabbed with a kitchen knife.",
            "time": "21:00",
            "day": 1,
            "location": "loc_victim_apartment",
            "involved_persons": ["p_victim", "p_julia"],
            "supporting_evidence": ["ev_knife"],
            "certainty_level": "CONFIRMED"
        },
        # Event 8 — Julia Leaves (21:05)
        {
            "id": "evt_julia_leaves",
            "description": "Footsteps heard in hallway as someone leaves quickly.",
            "time": "21:05",
            "day": 1,
            "location": "loc_hallway",
            "involved_persons": ["p_julia"],
            "supporting_evidence": ["ev_shoe_print", "ev_sarah_second_testimony"],
            "certainty_level": "LIKELY"
        }
    ],
    "statements": [
        # Initial statements (lies)
        {
            "id": "stmt_mark_initial",
            "person_id": "p_mark",
            "text": "I visited Daniel earlier but left around 20:30.",
            "day_given": 1,
            "related_evidence": [],
            "related_event": "evt_mark_leaves",
            "contradicting_evidence": ["ev_parking_camera"]
        },
        {
            "id": "stmt_julia_initial",
            "person_id": "p_julia",
            "text": "I wasn't at the apartment that night.",
            "day_given": 1,
            "related_evidence": [],
            "related_event": "",
            "contradicting_evidence": ["ev_julia_fingerprint_glass", "ev_elevator_logs", "ev_shoe_print"]
        },
        {
            "id": "stmt_sarah_initial",
            "person_id": "p_sarah",
            "text": "I heard some arguing but didn't see anything.",
            "day_given": 1,
            "related_evidence": ["ev_sarah_testimony"],
            "related_event": "evt_loud_argument",
            "contradicting_evidence": ["ev_hallway_camera"]
        },
        {
            "id": "stmt_lucas_initial",
            "person_id": "p_lucas",
            "text": "I finished work at 19:00.",
            "day_given": 1,
            "related_evidence": [],
            "related_event": "",
            "contradicting_evidence": ["ev_lucas_work_log"]
        },
        # Confronted statements
        {
            "id": "stmt_mark_confronted",
            "person_id": "p_mark",
            "text": "Alright... maybe it was closer to 20:40.",
            "day_given": 2,
            "related_evidence": ["ev_parking_camera"],
            "related_event": "evt_mark_leaves",
            "contradicting_evidence": []
        },
        {
            "id": "stmt_mark_financial",
            "person_id": "p_mark",
            "text": "This has nothing to do with the murder.",
            "day_given": 2,
            "related_evidence": ["ev_bank_transfer"],
            "related_event": "",
            "contradicting_evidence": ["ev_hidden_safe"]
        },
        {
            "id": "stmt_mark_embezzlement",
            "person_id": "p_mark",
            "text": "Daniel found out about the missing money. But I didn't kill him.",
            "day_given": 3,
            "related_evidence": ["ev_hidden_safe"],
            "related_event": "",
            "contradicting_evidence": []
        },
        {
            "id": "stmt_sarah_confronted",
            "person_id": "p_sarah",
            "text": "I may have heard a woman's voice...",
            "day_given": 2,
            "related_evidence": ["ev_hallway_camera"],
            "related_event": "",
            "contradicting_evidence": []
        },
        {
            "id": "stmt_sarah_footsteps",
            "person_id": "p_sarah",
            "text": "Someone walked past my door quickly.",
            "day_given": 2,
            "related_evidence": ["ev_shoe_print"],
            "related_event": "evt_julia_leaves",
            "contradicting_evidence": []
        },
        {
            "id": "stmt_julia_fingerprint",
            "person_id": "p_julia",
            "text": "I visited earlier in the day.",
            "day_given": 2,
            "related_evidence": ["ev_julia_fingerprint_glass"],
            "related_event": "",
            "contradicting_evidence": ["ev_elevator_logs"]
        },
        {
            "id": "stmt_julia_elevator",
            "person_id": "p_julia",
            "text": "Okay... I stopped by briefly. But Daniel was alive when I left.",
            "day_given": 2,
            "related_evidence": ["ev_elevator_logs"],
            "related_event": "evt_julia_arrives",
            "contradicting_evidence": ["ev_shoe_print", "ev_julia_shoes"]
        },
        {
            "id": "stmt_julia_confession",
            "person_id": "p_julia",
            "text": "He threatened to ruin everything. I just lost control.",
            "day_given": 3,
            "related_evidence": ["ev_personal_journal"],
            "related_event": "evt_murder",
            "contradicting_evidence": []
        }
    ],
    "actions": [
        {
            "id": "act_visit_apartment",
            "name": "Visit Victim's Apartment",
            "type": "VISIT_LOCATION",
            "time_cost": 1,
            "target": "loc_victim_apartment",
            "requirements": [],
            "results": []
        },
        {
            "id": "act_visit_hallway",
            "name": "Investigate Building Hallway",
            "type": "VISIT_LOCATION",
            "time_cost": 1,
            "target": "loc_hallway",
            "requirements": [],
            "results": []
        },
        {
            "id": "act_visit_parking",
            "name": "Check Parking Lot",
            "type": "VISIT_LOCATION",
            "time_cost": 1,
            "target": "loc_parking_lot",
            "requirements": [],
            "results": []
        },
        {
            "id": "act_visit_neighbor",
            "name": "Visit Neighbor's Apartment",
            "type": "VISIT_LOCATION",
            "time_cost": 1,
            "target": "loc_neighbor_apartment",
            "requirements": [],
            "results": []
        },
        {
            "id": "act_visit_office",
            "name": "Visit Victim's Office",
            "type": "VISIT_LOCATION",
            "time_cost": 1,
            "target": "loc_victim_office",
            "requirements": [],
            "results": []
        },
        {
            "id": "act_interrogate_mark",
            "name": "Interrogate Mark Bennett",
            "type": "INTERROGATION",
            "time_cost": 1,
            "target": "p_mark",
            "requirements": [],
            "results": []
        },
        {
            "id": "act_interrogate_sarah",
            "name": "Interrogate Sarah Klein",
            "type": "INTERROGATION",
            "time_cost": 1,
            "target": "p_sarah",
            "requirements": [],
            "results": []
        },
        {
            "id": "act_interrogate_julia",
            "name": "Interrogate Julia Ross",
            "type": "INTERROGATION",
            "time_cost": 1,
            "target": "p_julia",
            "requirements": [],
            "results": []
        },
        {
            "id": "act_interrogate_lucas",
            "name": "Interrogate Lucas Weber",
            "type": "INTERROGATION",
            "time_cost": 1,
            "target": "p_lucas",
            "requirements": [],
            "results": []
        }
    ],
    "insights": [
        {
            "id": "ins_embezzlement_scheme",
            "description": "Mark was embezzling money from the company. Daniel discovered the missing funds and planned to expose him.",
            "source_evidence": ["ev_bank_transfer", "ev_accounting_files", "ev_hidden_safe"],
            "strengthens_theory": "",
            "enables_warrant": "",
            "unlocks_topic": "topic_mark_embezzlement"
        },
        {
            "id": "ins_julia_presence",
            "description": "Julia was at the apartment on the night of the murder, contradicting her initial statement.",
            "source_evidence": ["ev_julia_fingerprint_glass", "ev_elevator_logs"],
            "strengthens_theory": "",
            "enables_warrant": "warrant_julia_search",
            "unlocks_topic": "topic_julia_presence"
        },
        {
            "id": "ins_hidden_relationships",
            "description": "Julia and Mark secretly met before the murder. Julia feared Daniel would expose the embezzlement and ruin them financially.",
            "source_evidence": ["ev_hidden_safe", "ev_personal_journal"],
            "strengthens_theory": "",
            "enables_warrant": "",
            "unlocks_topic": ""
        }
    ],
    "lab_requests": [
        {
            "id": "lab_fingerprint_glass",
            "input_evidence_id": "ev_wine_glasses",
            "analysis_type": "fingerprint_analysis",
            "day_submitted": 0,
            "completion_day": 2,
            "output_evidence_id": "ev_julia_fingerprint_glass"
        },
        {
            "id": "lab_fingerprint_desk",
            "input_evidence_id": "ev_mark_fingerprint_desk",
            "analysis_type": "fingerprint_analysis",
            "day_submitted": 0,
            "completion_day": 2,
            "output_evidence_id": "ev_mark_fingerprint_desk"
        },
        {
            "id": "lab_shoe_print",
            "input_evidence_id": "ev_shoe_print",
            "analysis_type": "footwear_analysis",
            "day_submitted": 0,
            "completion_day": 2,
            "output_evidence_id": "ev_shoe_print"
        }
    ],
    "surveillance_requests": [
        {
            "id": "surv_julia_phone",
            "target_person": "p_julia",
            "type": "PHONE_TAP",
            "day_installed": 0,
            "active_days": 2,
            "result_events": []
        },
        {
            "id": "surv_mark_financial",
            "target_person": "p_mark",
            "type": "FINANCIAL_MONITORING",
            "day_installed": 0,
            "active_days": 2,
            "result_events": []
        }
    ]
}


# =========================================================================
# events.json
# =========================================================================
EVENTS = {
    "event_triggers": [
        # Day 1 Morning Briefing
        {
            "id": "trig_morning_briefing_day1",
            "trigger_type": "DAY_START",
            "trigger_day": 1,
            "conditions": [],
            "actions": [
                "unlock_location:loc_victim_apartment",
                "unlock_location:loc_hallway",
                "unlock_location:loc_parking_lot",
                "unlock_location:loc_neighbor_apartment",
                "unlock_interrogation:p_mark",
                "unlock_interrogation:p_sarah",
                "notify:Morning Briefing - A man has been found dead in his apartment from a knife wound. Victim identified as Daniel Ross, age 42, financial consultant. The crime scene and building are now available for investigation. Mark Bennett and Sarah Klein are available for questioning."
            ],
            "result_events": []
        },
        # Day 2 Morning Briefing
        {
            "id": "trig_morning_briefing_day2",
            "trigger_type": "DAY_START",
            "trigger_day": 2,
            "conditions": [],
            "actions": [
                "unlock_location:loc_victim_office",
                "unlock_interrogation:p_julia",
                "unlock_interrogation:p_lucas",
                "notify:Day 2 Briefing - Lab results are arriving. Julia Ross and Lucas Weber have been identified as additional persons of interest. Daniel's office is now accessible for investigation."
            ],
            "result_events": []
        },
        # Lab results: fingerprints (Day 2)
        {
            "id": "trig_lab_fingerprints",
            "trigger_type": "TIMED",
            "trigger_day": 2,
            "conditions": [
                "evidence_discovered:ev_wine_glasses"
            ],
            "actions": [
                "deliver_lab_results:ev_julia_fingerprint_glass",
                "deliver_lab_results:ev_mark_fingerprint_desk",
                "notify:Lab results are in - fingerprints from the crime scene have been identified."
            ],
            "result_events": []
        },
        # Lab results: shoe print (Day 2)
        {
            "id": "trig_lab_shoe_print",
            "trigger_type": "TIMED",
            "trigger_day": 2,
            "conditions": [
                "evidence_discovered:ev_shoe_print"
            ],
            "actions": [
                "deliver_lab_results:ev_shoe_print",
                "notify:Lab results are in - the hallway shoe print has been analyzed."
            ],
            "result_events": []
        },
        # Office unlock (conditional - can open early if call log found)
        {
            "id": "trig_unlock_office",
            "trigger_type": "CONDITIONAL",
            "trigger_day": -1,
            "conditions": [
                "evidence_discovered:ev_mark_call_log"
            ],
            "actions": [
                "unlock_location:loc_victim_office",
                "notify:The call log reveals a business connection. Daniel's office is now available for investigation."
            ],
            "result_events": []
        },
        # Warrant: Julia's phone - unlocks deleted messages
        {
            "id": "trig_warrant_julia_phone",
            "trigger_type": "CONDITIONAL",
            "trigger_day": -1,
            "conditions": [
                "warrant_obtained:warrant_julia_phone"
            ],
            "actions": [
                "unlock_evidence:ev_deleted_messages",
                "notify:Warrant executed. Deleted messages from Julia's phone have been recovered."
            ],
            "result_events": []
        },
        # Warrant: Julia's search - unlocks shoes
        {
            "id": "trig_warrant_julia_search",
            "trigger_type": "CONDITIONAL",
            "trigger_day": -1,
            "conditions": [
                "warrant_obtained:warrant_julia_search"
            ],
            "actions": [
                "unlock_evidence:ev_julia_shoes",
                "notify:Search warrant executed at Julia's residence. Her shoes have been seized for comparison."
            ],
            "result_events": []
        },
        # Final day mandatory report
        {
            "id": "trig_final_day_pressure",
            "trigger_type": "DAY_START",
            "trigger_day": 4,
            "conditions": [],
            "actions": [
                "add_mandatory:submit_case_report",
                "notify:Final day of investigation. You must submit your case report to the prosecutor before end of day."
            ],
            "result_events": []
        }
    ],
    "interrogation_topics": [
        {
            "id": "topic_mark_departure",
            "person_id": "p_mark",
            "topic_name": "Mark's Departure Time",
            "trigger_conditions": ["evidence:ev_parking_camera"],
            "unlock_evidence": [],
            "statements": ["stmt_mark_confronted"],
            "required_evidence": ["ev_parking_camera"],
            "requires_statement_id": "stmt_mark_initial",
            "impact_level": "MAJOR"
        },
        {
            "id": "topic_mark_finances",
            "person_id": "p_mark",
            "topic_name": "Financial Dispute",
            "trigger_conditions": ["evidence:ev_bank_transfer"],
            "unlock_evidence": [],
            "statements": ["stmt_mark_financial"],
            "required_evidence": ["ev_bank_transfer"],
            "requires_statement_id": "",
            "impact_level": "MAJOR"
        },
        {
            "id": "topic_mark_embezzlement",
            "person_id": "p_mark",
            "topic_name": "The Embezzlement",
            "trigger_conditions": ["evidence:ev_hidden_safe"],
            "unlock_evidence": [],
            "statements": ["stmt_mark_embezzlement"],
            "required_evidence": ["ev_hidden_safe"],
            "requires_statement_id": "",
            "impact_level": "BREAKPOINT"
        },
        {
            "id": "topic_sarah_hallway",
            "person_id": "p_sarah",
            "topic_name": "What Sarah Saw",
            "trigger_conditions": ["evidence:ev_hallway_camera"],
            "unlock_evidence": [],
            "statements": ["stmt_sarah_confronted"],
            "required_evidence": ["ev_hallway_camera"],
            "requires_statement_id": "stmt_sarah_initial",
            "impact_level": "MAJOR"
        },
        {
            "id": "topic_julia_presence",
            "person_id": "p_julia",
            "topic_name": "Julia's Presence at Apartment",
            "trigger_conditions": ["evidence:ev_julia_fingerprint_glass"],
            "unlock_evidence": [],
            "statements": ["stmt_julia_fingerprint"],
            "required_evidence": ["ev_julia_fingerprint_glass"],
            "requires_statement_id": "stmt_julia_initial",
            "impact_level": "MAJOR"
        },
        {
            "id": "topic_julia_elevator",
            "person_id": "p_julia",
            "topic_name": "Elevator Evidence",
            "trigger_conditions": ["evidence:ev_elevator_logs"],
            "unlock_evidence": [],
            "statements": ["stmt_julia_elevator"],
            "required_evidence": ["ev_elevator_logs"],
            "requires_statement_id": "stmt_julia_fingerprint",
            "impact_level": "MAJOR"
        },
        {
            "id": "topic_lucas_work",
            "person_id": "p_lucas",
            "topic_name": "Lucas's Work Schedule",
            "trigger_conditions": ["evidence:ev_lucas_work_log"],
            "unlock_evidence": [],
            "statements": [],
            "required_evidence": ["ev_lucas_work_log"],
            "requires_statement_id": "stmt_lucas_initial",
            "impact_level": "MINOR"
        }
    ],
    "interrogation_triggers": [
        # Mark - Parking Camera
        {
            "id": "itrig_mark_parking",
            "person_id": "p_mark",
            "evidence_id": "ev_parking_camera",
            "requires_statement_id": "stmt_mark_initial",
            "impact_level": "MAJOR",
            "reaction_type": "ADMISSION",
            "dialogue": "Alright... maybe it was closer to 20:40.",
            "new_statement_id": "stmt_mark_confronted",
            "unlocks": [],
            "pressure_points": 2,
            "deflection_target_id": ""
        },
        # Mark - Bank Transfer
        {
            "id": "itrig_mark_bank",
            "person_id": "p_mark",
            "evidence_id": "ev_bank_transfer",
            "requires_statement_id": "",
            "impact_level": "MAJOR",
            "reaction_type": "DEFLECTION",
            "dialogue": "This has nothing to do with the murder.",
            "new_statement_id": "stmt_mark_financial",
            "unlocks": [],
            "pressure_points": 2,
            "deflection_target_id": "p_julia"
        },
        # Mark - Hidden Safe Documents
        {
            "id": "itrig_mark_safe",
            "person_id": "p_mark",
            "evidence_id": "ev_hidden_safe",
            "requires_statement_id": "",
            "impact_level": "BREAKPOINT",
            "reaction_type": "ADMISSION",
            "dialogue": "Daniel found out about the missing money. But I didn't kill him.",
            "new_statement_id": "stmt_mark_embezzlement",
            "unlocks": [],
            "pressure_points": 3,
            "deflection_target_id": ""
        },
        # Sarah - Hallway Camera
        {
            "id": "itrig_sarah_camera",
            "person_id": "p_sarah",
            "evidence_id": "ev_hallway_camera",
            "requires_statement_id": "stmt_sarah_initial",
            "impact_level": "MAJOR",
            "reaction_type": "ADMISSION",
            "dialogue": "I may have heard a woman's voice...",
            "new_statement_id": "stmt_sarah_confronted",
            "unlocks": [],
            "pressure_points": 2,
            "deflection_target_id": ""
        },
        # Sarah - Shoe Print
        {
            "id": "itrig_sarah_shoe",
            "person_id": "p_sarah",
            "evidence_id": "ev_shoe_print",
            "requires_statement_id": "stmt_sarah_confronted",
            "impact_level": "MINOR",
            "reaction_type": "ADMISSION",
            "dialogue": "Someone walked past my door quickly.",
            "new_statement_id": "stmt_sarah_footsteps",
            "unlocks": [],
            "pressure_points": 1,
            "deflection_target_id": ""
        },
        # Julia - Fingerprint on Wine Glass
        {
            "id": "itrig_julia_fingerprint",
            "person_id": "p_julia",
            "evidence_id": "ev_julia_fingerprint_glass",
            "requires_statement_id": "stmt_julia_initial",
            "impact_level": "MAJOR",
            "reaction_type": "DEFLECTION",
            "dialogue": "I visited earlier in the day.",
            "new_statement_id": "stmt_julia_fingerprint",
            "unlocks": [],
            "pressure_points": 2,
            "deflection_target_id": "p_mark"
        },
        # Julia - Elevator Log
        {
            "id": "itrig_julia_elevator",
            "person_id": "p_julia",
            "evidence_id": "ev_elevator_logs",
            "requires_statement_id": "stmt_julia_fingerprint",
            "impact_level": "MAJOR",
            "reaction_type": "ADMISSION",
            "dialogue": "Okay... I stopped by briefly. But Daniel was alive when I left.",
            "new_statement_id": "stmt_julia_elevator",
            "unlocks": [],
            "pressure_points": 2,
            "deflection_target_id": ""
        },
        # Julia - Shoe Print Match
        {
            "id": "itrig_julia_shoes",
            "person_id": "p_julia",
            "evidence_id": "ev_julia_shoes",
            "requires_statement_id": "stmt_julia_elevator",
            "impact_level": "MAJOR",
            "reaction_type": "PANIC",
            "dialogue": "That... that doesn't prove anything! I told you I stopped by briefly!",
            "new_statement_id": "",
            "unlocks": [],
            "pressure_points": 3,
            "deflection_target_id": ""
        },
        # Julia - Personal Journal (BREAKPOINT)
        {
            "id": "itrig_julia_journal",
            "person_id": "p_julia",
            "evidence_id": "ev_personal_journal",
            "requires_statement_id": "stmt_julia_elevator",
            "impact_level": "BREAKPOINT",
            "reaction_type": "PARTIAL_CONFESSION",
            "dialogue": "He threatened to ruin everything. I just lost control.",
            "new_statement_id": "stmt_julia_confession",
            "unlocks": [],
            "pressure_points": 4,
            "deflection_target_id": ""
        },
        # Lucas - Work Log
        {
            "id": "itrig_lucas_work",
            "person_id": "p_lucas",
            "evidence_id": "ev_lucas_work_log",
            "requires_statement_id": "stmt_lucas_initial",
            "impact_level": "MINOR",
            "reaction_type": "ADMISSION",
            "dialogue": "Fine, I was working until 20:00, not 19:00. But I was in the basement the whole time, nowhere near his apartment.",
            "new_statement_id": "",
            "unlocks": [],
            "pressure_points": 1,
            "deflection_target_id": ""
        },
        # Lucas - Elevator Logs (clears him)
        {
            "id": "itrig_lucas_elevator",
            "person_id": "p_lucas",
            "evidence_id": "ev_elevator_logs",
            "requires_statement_id": "",
            "impact_level": "MINOR",
            "reaction_type": "ADMISSION",
            "dialogue": "See? My key card wasn't used for the elevator. I took the stairs to the basement. I never went to his floor.",
            "new_statement_id": "",
            "unlocks": [],
            "pressure_points": 0,
            "deflection_target_id": ""
        }
    ]
}


# =========================================================================
# discovery_rules.json
# =========================================================================
DISCOVERY_RULES = {
    "discovery_rules": [
        # Fingerprint results require lab processing
        {
            "id": "dr_julia_fingerprint_glass",
            "evidence_id": "ev_julia_fingerprint_glass",
            "location_id": "loc_victim_apartment",
            "conditions": [
                "evidence_discovered:ev_wine_glasses",
                "day_gte:2"
            ],
            "description": "Julia's fingerprint on the wine glass is revealed through lab analysis after discovering the glasses."
        },
        {
            "id": "dr_mark_fingerprint_desk",
            "evidence_id": "ev_mark_fingerprint_desk",
            "location_id": "loc_victim_apartment",
            "conditions": [
                "day_gte:2"
            ],
            "description": "Mark's fingerprint on the desk is identified through lab analysis on Day 2."
        },
        # Hallway camera and elevator logs need visiting the hallway
        {
            "id": "dr_hallway_camera",
            "evidence_id": "ev_hallway_camera",
            "location_id": "loc_hallway",
            "conditions": [
                "location_visited:loc_hallway"
            ],
            "description": "The hallway camera footage becomes available after visiting the building hallway."
        },
        {
            "id": "dr_elevator_logs",
            "evidence_id": "ev_elevator_logs",
            "location_id": "loc_hallway",
            "conditions": [
                "location_visited:loc_hallway"
            ],
            "description": "Elevator access logs become available after visiting the building hallway."
        },
        # Parking camera needs visiting parking lot
        {
            "id": "dr_parking_camera",
            "evidence_id": "ev_parking_camera",
            "location_id": "loc_parking_lot",
            "conditions": [
                "location_visited:loc_parking_lot"
            ],
            "description": "The parking lot camera footage becomes available after visiting the parking lot."
        },
        # Sarah second testimony requires first testimony and pressure
        {
            "id": "dr_sarah_second_testimony",
            "evidence_id": "ev_sarah_second_testimony",
            "location_id": "loc_neighbor_apartment",
            "conditions": [
                "evidence_discovered:ev_sarah_testimony",
                "evidence_discovered:ev_hallway_camera"
            ],
            "description": "Sarah gives a more detailed testimony after being confronted with the hallway camera footage."
        },
        # Shoe print lab results
        {
            "id": "dr_shoe_print",
            "evidence_id": "ev_shoe_print",
            "location_id": "loc_hallway",
            "conditions": [
                "location_visited:loc_hallway",
                "day_gte:2"
            ],
            "description": "The shoe print in the hallway is discovered by forensics and analyzed in the lab."
        },
        # Hidden safe requires finding accounting files first
        {
            "id": "dr_hidden_safe",
            "evidence_id": "ev_hidden_safe",
            "location_id": "loc_victim_office",
            "conditions": [
                "evidence_discovered:ev_accounting_files"
            ],
            "description": "The hidden safe is found after discovering the accounting irregularities and searching the office thoroughly."
        },
        # Personal journal requires visiting office and Day 3
        {
            "id": "dr_personal_journal",
            "evidence_id": "ev_personal_journal",
            "location_id": "loc_victim_office",
            "conditions": [
                "location_visited:loc_victim_office",
                "day_gte:3"
            ],
            "description": "Daniel's personal journal is found during a thorough search of his office on Day 3 or later."
        },
        # Deleted messages require warrant
        {
            "id": "dr_deleted_messages",
            "evidence_id": "ev_deleted_messages",
            "location_id": "loc_victim_apartment",
            "conditions": [
                "warrant_obtained:warrant_julia_phone",
                "day_gte:3"
            ],
            "description": "Deleted messages are recovered after obtaining a warrant to search Julia's phone."
        },
        # Julia's shoes require search warrant
        {
            "id": "dr_julia_shoes",
            "evidence_id": "ev_julia_shoes",
            "location_id": "loc_victim_apartment",
            "conditions": [
                "warrant_obtained:warrant_julia_search"
            ],
            "description": "Julia's shoes are seized under a search warrant for comparison with the hallway shoe print."
        },
        # Julia's financial records need Day 3
        {
            "id": "dr_julia_financial_records",
            "evidence_id": "ev_julia_financial_records",
            "location_id": "loc_victim_office",
            "conditions": [
                "day_gte:3"
            ],
            "description": "Julia's financial records become available through investigation on Day 3."
        }
    ]
}


# =========================================================================
# Main
# =========================================================================
if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("Generating case data for: The Riverside Apartment Murder")
    write_json("case.json", CASE)
    write_json("suspects.json", SUSPECTS)
    write_json("locations.json", LOCATIONS)
    write_json("evidence.json", EVIDENCE)
    write_json("timeline.json", TIMELINE)
    write_json("events.json", EVENTS)
    write_json("discovery_rules.json", DISCOVERY_RULES)
    print("Done! All 7 JSON files generated.")
