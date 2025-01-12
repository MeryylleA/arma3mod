class CfgPatches {
    class AIAI_Main {
        units[] = {};
        weapons[] = {};
        requiredVersion = 0.1;
        requiredAddons[] = {"A3_Data_F", "A3_Characters_F"};
        author = "Meryylle";
        authorUrl = "";
        version = "0.1";
        versionStr = "0.1";
        versionAr[] = {0,1,0};
    };
};

class CfgFunctions {
    class AIAI {
        class Commander {
            file = "\AIAI\addons\main\functions\commander";
            class initCommander {};
            class spawnTroops {};
            class setOrders {};
            class getAvailableUnits {};
        };
        
        class AI {
            file = "\AIAI\addons\main\functions\ai";
            class initAI {};
            class handleAIBehavior {};
            class analyzeTerrain {};
            class coordinateUnits {};
        };
        
        class Utils {
            file = "\AIAI\addons\main\functions\utils";
            class getAvailableUnits {};
            class createUIElements {};
            class logSystem {};
            class errorHandler {};
            class performanceMonitor {};
        };
    };
};

class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Default;
            class Edit;
            class Combo;
            class Checkbox;
            class CheckboxNumber;
            class ModuleDescription;
        };
        class ModuleDescription;
    };
    
    class AIAI_ModuleCommander: Module_F {
        scope = 2;
        displayName = "AI Commander";
        icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa";
        category = "AIAI";
        
        function = "AIAI_fnc_initCommander";
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        
        class Arguments {
            class Side {
                displayName = "Side";
                description = "Commander's side";
                typeName = "STRING";
                class values {
                    class WEST {
                        name = "BLUFOR";
                        value = "WEST";
                        default = 1;
                    };
                    class EAST {
                        name = "OPFOR";
                        value = "EAST";
                    };
                    class GUER {
                        name = "Independent";
                        value = "GUER";
                    };
                };
            };
            
            class DebugMode {
                displayName = "Debug Mode";
                description = "Enable debug logging and visualization";
                typeName = "BOOL";
                defaultValue = "false";
            };
            
            class AISkill {
                displayName = "AI Skill Level";
                description = "Set the base skill level for AI units";
                typeName = "NUMBER";
                class values {
                    class Low {
                        name = "Low";
                        value = 0.3;
                    };
                    class Medium {
                        name = "Medium";
                        value = 0.6;
                        default = 1;
                    };
                    class High {
                        name = "High";
                        value = 0.9;
                    };
                };
            };
            
            class TacticStyle {
                displayName = "Tactic Style";
                description = "Preferred tactical approach";
                typeName = "STRING";
                class values {
                    class Balanced {
                        name = "Balanced";
                        value = "BALANCED";
                        default = 1;
                    };
                    class Aggressive {
                        name = "Aggressive";
                        value = "AGGRESSIVE";
                    };
                    class Defensive {
                        name = "Defensive";
                        value = "DEFENSIVE";
                    };
                };
            };
        };
        
        class ModuleDescription: ModuleDescription {
            description = "Creates an AI Commander with advanced tactical capabilities";
        };
    };
};
