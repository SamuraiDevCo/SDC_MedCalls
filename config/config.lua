SDC = {}

---------------------------------------------------------------------------------
-------------------------------Important Configs---------------------------------
---------------------------------------------------------------------------------
SDC.Framework = "qb-core" --Either "qb-core" or "esx"
SDC.NotificationSystem = "framework" -- ['mythic_old', 'mythic_new', 'tnotify', 'okoknotify', 'print', 'framework', 'none'] --Notification system you prefer to use
SDC.UseProgBar = "ox_lib" --If you want to use a progress bar resource, options: ["progressBars", "mythic_progbar", "ox_lib", "none"]

SDC.EMSJobs = { --All jobs that will recieve these calls
    ["ambulance"] = true
}

SDC.RandomCallTimer = {15, 30} --How often a random call will be triggered, min/max (In Minutes)
SDC.MaxCallsAtATime = 3 --How many calls can be active at once
SDC.MaxCallTime = 30 --How long a single call can possibly last before auto removing call (In Minutes)

SDC.CallChances = { --All call chances (0-100 ratio)
    AssistanceNeeded = 0,
    HospitalTransport = 100
}
SDC.FinishCallReward = { --All rewards for calls
    AssistanceNeeded = math.random(500, 1500),
    HospitalTransport =  math.random(500, 1000),
}

SDC.Keybinds = { --All keybinds for the resource
    PreformCheckup = {Input = 38, Label = "E"},
    GrabStretcher = {Input = 38, Label = "E"},
    PickupPed = {Input = 47, Label = "G"},
    DropoffPed = {Input = 38, Label = "E"},
}

SDC.ShowVitalHelpers = true --If you want it to show vital helpers. (EX: Showing "low"/"normal"/"high" after the vital)

SDC.Icons = { --All icon configs (if you want them on set enabled to true)
    Checkup = {Enabled = true, DistToDraw = 7},
    Stretcher = {Enabled = true, DistToDraw = 7},
    PutOnStrecher = {Enabled = true, DistToDraw = 7},
    DropOff = {Enabled = true, DistToDraw = 7},
    Transports = {Enabled = true, DistToDraw = 7}
}

---------------------------------------------------------------------------------
-------------------------------Stretcher Configs---------------------------------
---------------------------------------------------------------------------------
SDC.VehiclesWithStretchers = { --All Whitelisted Vehicles for pulling out stretchers 
    ["ambulance"] = {GrabOffset = {vec3(0.0, -4.0, 0.0)}}
}
SDC.StretcherModel = "prop_stretcher" --The stretcher prop used in the resources
SDC.StretcherSettings = { --The offsets for the corresponding stretcher model
    Pushing = {Offset = {vec3(0.0, 1.5, 0.0)}, Rotation = vec3(0.0, 0.0, 180.0)}, --Pushing Stretcher Offset
    OnStrecher = {Offset = {vec3(0.0, 0.0, 1.0)}, Rotation = vec3(0.0, 0.0, 180.0)} --Ped Laying On Top Offset
}

---------------------------------------------------------------------------------
-------------------------------Injury Configs------------------------------------
---------------------------------------------------------------------------------
SDC.StatusConfigs = { --All Status Configs (Recommend Not Touching This)
    Unconscious = {Dict = "missarmenian2", Anim = "drunk_loop"},
    Conscious = {Dict = "anim@amb@business@bgen@bgen_no_work@", Anim = "sit_phone_phoneputdown_idle_nowork"},
}

SDC.RandomInjuryCount = {1, 3} --Random Injury Count, min/max
SDC.Injuries = { --All Injury Configs (Recommend Not Touching This)
    ["Right Leg"] = {"Broken", "Fractured", "Bruised"},
    ["Left Leg"] = {"Broken", "Fractured", "Bruised"},
    ["Right Foot"] = {"Broken", "Fractured", "Bruised"},
    ["Left Foot"] = {"Broken", "Fractured", "Bruised"},
    ["Right Ribs"] = {"Broken", "Fractured", "Bruised"},
    ["Left Ribs"] = {"Broken", "Fractured", "Bruised"},
    ["Right Arm"] = {"Broken", "Fractured", "Bruised"},
    ["Left Arm"] = {"Broken", "Fractured", "Bruised"},
    ["Right Hand"] = {"Broken", "Fractured", "Bruised"},
    ["Left Hand"] = {"Broken", "Fractured", "Bruised"},
}

SDC.RandomComplaintCount = {1, 5} --Random Complaint Count, min/max
SDC.Complaints = { --Advanced Complaint Configs (Recommend Not Touching This)
    ["Neck Pain"] = {"Minor", "Major"},
    ["Chest Pain"] = {"Minor", "Major"},
    ["Abdominal Pain"] = {"Minor", "Major"},
    ["Heartburn Pain"] = {"Minor", "Major"},
    ["Groin Pain"] = {"Minor", "Major"},
    ["Back Pain"] = {"Minor", "Major"},
    ["Headache"] = {"Minor", "Major"},
}
SDC.ExtraComplaints = { --Complaint Configs (Recommend Not Touching This)
    "Back Is Numb",
    "Continuous Muscle Spasms",
    "Shortness Of Breath",
    "Coughing Blood",
    "Have Cold Sweats",
    "Nose Bleed",
    "Ear Bleed",
    "Nauseous",
    "Has Trouble Breathing",
    "Has Trouble Swallowing",
    "Uncontrollably Vomiting",
    "Has Trouble Speaking",
    "Blurred Vision",
    "Double Vision",
    "Eyes Sensitive To Light",
    "Hives",
}

SDC.RandomObservationCount = {1, 3} --Random Observation Count, min/max
SDC.Observations = { --Observation Configs (Recommend Not Touching This)
    "Lips Are Blue",
    "Face Is Pale/Clammy",
    "Skin Is Pale/Clammy",
    "Can't Remember Name",
    "Smells Like Weed",
    "Smells Like Alcohol",
    "Dilated Eyes",
    "Sweating",
    "Yellow Skin",
    "Yellow Eyes",
    "Barrel Shaped Chest",
    "Railes",
    "Stridor",
    "Wheezing",
    "Flail Chest",
    "Anxious",
    "Jugular Vein Distension",
    "Blue Skin",
}

SDC.VitalSettings = { --DO NOT TOUCH UNLESS YOU KNOW WHAT YOU ARE DOING (MODIFICATION WITHOUT KNOWING WILL CAUSE ISSUES)
    BP = {--DO NOT TOUCH UNLESS YOU KNOW WHAT YOU ARE DOING (MODIFICATION WITHOUT KNOWING WILL CAUSE ISSUES)
        UpperConstraints = {Min = 70, Max = 190},
        LowerDifferanceFromUpper = {Min = 20, Max = 30},
        UpperCategories = {
            Low = 90,
            Normal = 120,
            High = 190
        }
    },
    Heartrate = {--DO NOT TOUCH UNLESS YOU KNOW WHAT YOU ARE DOING (MODIFICATION WITHOUT KNOWING WILL CAUSE ISSUES)
        BPComparison = {
            Low = {Min = 40, Max = 50},
            Normal = {Min = 51, Max = 95},
            High = {Min = 96, Max = 180},
        }
    },
    RespiratoryRate = {--DO NOT TOUCH UNLESS YOU KNOW WHAT YOU ARE DOING (MODIFICATION WITHOUT KNOWING WILL CAUSE ISSUES)
        HeartrateComparison = {
            Low = {Min = 3, Max = 12},
            Normal = {Min = 13, Max = 20},
            High = {Min = 21, Max = 45},
        }
    },
    BloodSugar = {--DO NOT TOUCH UNLESS YOU KNOW WHAT YOU ARE DOING (MODIFICATION WITHOUT KNOWING WILL CAUSE ISSUES)
        Low = {Min = 0, Max = 75},
        Normal = {Min = 76, Max = 120},
        High = {Min = 121, Max = 200},
    },
    Temperature = {--DO NOT TOUCH UNLESS YOU KNOW WHAT YOU ARE DOING (MODIFICATION WITHOUT KNOWING WILL CAUSE ISSUES)
        Low = {Min = 90.0, Max = 96.0},
        Normal = {Min = 96.1, Max = 98.0},
        High = {Min = 98.1, Max = 105.0},
    }
}

SDC.RandomAge = {18, 55} --Random Age Assigned To Civilian, min/max
SDC.RandomHeight = {55, 80}  --Random Height Assigned To Civilian, min/max (Default Is Inches)

SDC.DropOffBlip = {Sprite = 153, Color = 1, Size = 1.5} --Blip Configs For Dropping Off Civilian
SDC.HospitalDropOff = { --All Drop Off Locations For Injury Calls
    {
        Label = "Pillbox Medical Center",
        DropOffCoords = vec3(298.5804, -584.6007, 43.2608)
    },
    {
        Label = "Central LS Medical Center",
        DropOffCoords = vec3(294.7614, -1448.0492, 29.9666)
    },
    {
        Label = "Mount Zonah Medical Center",
        DropOffCoords = vec3(-498.2917, -335.7869, 34.5017)
    },
    {
        Label = "Paleto Medical Center",
        DropOffCoords = vec3(-243.0228, 6325.3140, 32.4261)
    }
}
---------------------------------------------------------------------------------
-------------------------Injury Call Configs-------------------------------------
---------------------------------------------------------------------------------
SDC.InjuryBlip = {Sprite = 280, Color = 35, Size = 1.5} --Blip Configs For Injured Civilians
SDC.CheckupAnimTime = 10 --Animation Time For Preforming A Checkup (In Seconds)
SDC.CallCoords = { --All Random Injury Call Coords
    vec4(1044.5402, 201.8757, 80.9911, 159.4642),
    vec4(-784.9809, -419.5828, 36.2949, 113.2604),
    vec4(-1138.5847, -434.0219, 35.9652, 203.9175),
    vec4(-1256.7612, -749.7489, 20.6847, 220.4561),
    vec4(-1108.2380, -1067.0459, 2.1444, 249.1306),
    vec4(-977.2069, -1507.6876, 5.2313, 205.3206),
    vec4(-1327.5702, -1142.7534, 4.3177, 124.1230),
    vec4(-106.5067, -400.2293, 36.0931, 345.5924),
    vec4(921.5078, -557.9823, 57.9964, 155.5643),
    vec4(824.7878, -785.8456, 26.1861, 171.6957),
    vec4(1120.1512, -991.5194, 46.0290, 221.0254),
    vec4(954.1887, -1509.0623, 30.9655, 182.5065),
    vec4(1015.7194, -2146.0317, 30.5505, 252.2155),
    vec4(1228.6277, -2347.9543, 50.3895, 100.4568),
    vec4(923.8749, -2492.5740, 29.5715, 86.2536),
    vec4(283.0688, -2856.1089, 6.0124, 231.3142),
    vec4(792.3094, -2997.8938, 6.0254, 304.7523),
    vec4(-477.1893, -2687.6467, 8.7610, 41.7079)
}

---------------------------------------------------------------------------------
----------------------------Transport Call Configs-------------------------------
---------------------------------------------------------------------------------
SDC.TransportBlip = {Sprite = 280, Color = 16, Size = 1.5} --Blip Configs For Picking Up Transport Patient
SDC.PickupAnimTime = 10 --Animation Time For Picking Up The Transport Patient (In Seconds)
SDC.PickupDropoffs = { --All Hospital Locations For Medical Transports
    {
        Label = "Pillbox Medical Center",
        Coords = vec3(298.5804, -584.6007, 43.2608)
    },
    {
        Label = "Central LS Medical Center",
        Coords = vec3(294.7614, -1448.0492, 29.9666)
    },
    {
        Label = "Mount Zonah Medical Center",
        Coords = vec3(-498.2917, -335.7869, 34.5017)
    },
}

---------------------------------------------------------------------------------
-------------------------------Ped Model Configs---------------------------------
---------------------------------------------------------------------------------
SDC.PedModels = { --All random ped models
    "s_m_m_lifeinvad_01",
    "a_f_m_bevhills_02",
    "a_f_o_soucent_02",
    "a_f_m_soucent_02",
    "a_f_y_tourist_02",
    "a_m_m_business_01",
    "a_m_m_fatlatin_01",
    "a_m_m_soucent_03",
    "a_m_y_genstreet_02",
    "a_m_y_vinewood_04",
    "g_m_m_korboss_01"
}

---------------------------------------------------------------------------------
-----------------------------Random Name Configs---------------------------------
---------------------------------------------------------------------------------
SDC.FirstNames = { --All random first names
    "James",
    "Micheal",
    "Robert",
    "Mary",
    "Patricia",
    "Linda",
    "Joseph",
    "William",
    "Richard",
    "Lisa",
    "Sarah",
    "Nancy",
    "Charles",
    "Daniel",
    "Mark",
    "Donald",
    "Susan",
    "Elizebeth",
    "Betty",
    "Ashley",
    "Emily",
    "Mathew",
    "Anthony",
    "Thomas",
    "John",
    "Ryan",
    "Gary",
    "Luara",
    "Rebecca",
    "Donna",
    "Carol",
    "Eric",
    "Jason",
    "George",
    "Paul",
    "Emma",
    "Amy",
    "Kathleen",
    "Dorothy",
    "Jeffrey",
    "Jeff",
    "Ronald",
    "Brian",
    "Kevin",
    "Patrick",
    "Frank",
    "Maria",
    "Olivia",
    "Debra",
    "Tyler",
    "Aaron",
    "Jose",
    "Julie",
}
SDC.LastNames = { --All random last names
    "Aish",
    "Akers",
    "Acron",
    "Abson",
    "Barralet",
    "Ballam",
    "Bilbo",
    "Bisland",
    "Cade",
    "Kane",
    "Cardy",
    "Canyers",
    "Carrie",
    "Carrow",
    "Caley",
    "Dabel",
    "Daine",
    "Dukes",
    "Eastman",
    "Eagles",
    "Eddon",
    "Fox",
    "Farbus",
    "Faul",
    "Fant",
    "Gallie",
    "Gally",
    "Gallup",
    "Hut",
    "Hannton",
    "Halnan",
    "Ida",
    "Isgot",
    "Inshaw",
    "Jacklett",
    "Jaycox",
    "Jak",
    "Karn",
    "Kendel",
    "Moore",
    "Siera",
    "Nile",
    "Pontell",
    "Riez",
    "Madison",
    "Ossie",
    "Wales",
    "Yankee",
    "Zeon",
    "Udon",
}