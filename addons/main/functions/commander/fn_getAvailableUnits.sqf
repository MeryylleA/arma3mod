/*
 * Author: Meryylle
 * Retorna as unidades disponíveis para o comandante baseado no seu lado
 *
 * Arguments:
 * 0: Side <SIDE> - Lado do comandante (WEST, EAST, GUER)
 *
 * Return Value:
 * ARRAY - Array de configs das unidades disponíveis
 *
 * Example:
 * [west] call AIAI_fnc_getAvailableUnits
 */

params [["_side", west, [west]]];

private _units = [];
private _cfgVehicles = configFile >> "CfgVehicles";

// Prefixos baseados no lado
private _prefix = switch (_side) do {
    case west: { "B_" };
    case east: { "O_" };
    case resistance: { "I_" };
    default { "B_" };
};

// Categorias de unidades
private _categories = [
    "Infantry",
    "Armored",
    "Air",
    "Support"
];

{
    private _category = _x;
    
    // Procura por unidades que correspondem ao prefixo e categoria
    for "_i" from 0 to (count _cfgVehicles - 1) do {
        private _vehicle = _cfgVehicles select _i;
        
        if (isClass _vehicle) then {
            private _className = configName _vehicle;
            private _simulation = getText (_vehicle >> "simulation");
            
            // Verifica se a unidade pertence ao lado correto
            if (_className find _prefix == 0) then {
                private _scope = getNumber (_vehicle >> "scope");
                private _side = getNumber (_vehicle >> "side");
                
                // Adiciona apenas unidades jogáveis (scope == 2)
                if (_scope == 2) then {
                    switch (_category) do {
                        case "Infantry": {
                            if (_simulation == "soldier") then {
                                _units pushBack _className;
                            };
                        };
                        case "Armored": {
                            if (_simulation in ["tankx", "car"]) then {
                                _units pushBack _className;
                            };
                        };
                        case "Air": {
                            if (_simulation in ["helicopter", "airplane"]) then {
                                _units pushBack _className;
                            };
                        };
                        case "Support": {
                            if (_simulation in ["soldier"]) then {
                                if (_className find "_support" > -1 || _className find "_medic" > -1) then {
                                    _units pushBack _className;
                                };
                            };
                        };
                    };
                };
            };
        };
    };
} forEach _categories;

_units
