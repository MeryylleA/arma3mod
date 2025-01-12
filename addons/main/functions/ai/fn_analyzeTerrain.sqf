/*
 * Author: Meryylle
 * Analisa o terreno ao redor para identificar posições táticas
 *
 * Arguments:
 * 0: Posição Central <ARRAY>
 * 1: Raio de Análise <NUMBER>
 *
 * Return Value:
 * ARRAY - [
 *     Pontos Altos (Array),
 *     Coberturas (Array),
 *     Rotas de Flanqueamento (Array),
 *     Pontos de Observação (Array)
 * ]
 *
 * Example:
 * [getPos player, 300] call AIAI_fnc_analyzeTerrain
 */

params [
    ["_centerPos", [0,0,0], [[]]],
    ["_radius", 300, [0]]
];

// Arrays para armazenar diferentes tipos de posições
private _highPoints = [];
private _coverPositions = [];
private _flankRoutes = [];
private _observationPoints = [];

// Encontrar pontos altos
for "_i" from 0 to 360 step 45 do {
    for "_d" from 50 to _radius step 50 do {
        private _checkPos = _centerPos getPos [_d, _i];
        private _height = getTerrainHeightASL _checkPos;
        private _centerHeight = getTerrainHeightASL _centerPos;
        
        // Se o ponto for significativamente mais alto
        if (_height > _centerHeight + 5) then {
            // Verificar se tem boa visibilidade
            private _visible = 0;
            for "_v" from 0 to 360 step 45 do {
                private _testPos = _checkPos getPos [100, _v];
                if (terrainIntersectASL [AGLtoASL _checkPos, AGLtoASL _testPos]) then {
                    _visible = _visible + 1;
                };
            };
            
            // Se tiver boa visibilidade do entorno
            if (_visible >= 5) then {
                _highPoints pushBack [_checkPos, _height - _centerHeight];
            };
        };
    };
};

// Encontrar coberturas (objetos que podem servir de proteção)
private _nearObjects = nearestTerrainObjects [_centerPos, ["HOUSE", "WALL", "ROCK", "TREE"], _radius];
{
    private _obj = _x;
    private _pos = getPos _obj;
    private _size = sizeOf typeOf _obj;
    
    // Filtrar objetos adequados para cobertura
    if (_size > 2 && _size < 15) then {
        private _coverQuality = 0;
        
        // Avaliar qualidade da cobertura
        for "_i" from 0 to 360 step 90 do {
            private _testPos = _pos getPos [_size + 2, _i];
            if (lineIntersects [AGLtoASL _pos, AGLtoASL _testPos]) then {
                _coverQuality = _coverQuality + 1;
            };
        };
        
        if (_coverQuality >= 2) then {
            _coverPositions pushBack [_pos, _coverQuality, _obj];
        };
    };
} forEach _nearObjects;

// Identificar rotas de flanqueamento
private _sectors = [];
for "_i" from 0 to 315 step 45 do {
    private _sectorStart = _i;
    private _sectorEnd = _i + 45;
    private _midPoint = _centerPos getPos [_radius * 0.7, _i + 22.5];
    
    private _sectorCover = 0;
    private _pathClear = true;
    
    // Verificar densidade de cobertura no setor
    {
        private _pos = _x select 0;
        if ((_pos getDir _centerPos) >= _sectorStart && (_pos getDir _centerPos) <= _sectorEnd) then {
            _sectorCover = _sectorCover + 1;
        };
    } forEach _coverPositions;
    
    // Verificar se o caminho é navegável
    for "_d" from 20 to _radius step 20 do {
        private _checkPos = _centerPos getPos [_d, _i + 22.5];
        if (!isOnRoad _checkPos && surfaceIsWater _checkPos) then {
            _pathClear = false;
        };
    };
    
    // Se o setor tiver cobertura adequada e caminho livre
    if (_sectorCover >= 3 && _pathClear) then {
        _flankRoutes pushBack [_midPoint, _i + 22.5, _sectorCover];
    };
};

// Identificar pontos de observação
{
    private _pos = _x select 0;
    private _height = _x select 1;
    
    private _visibleArea = 0;
    private _concealment = 0;
    
    // Avaliar visibilidade e ocultação
    for "_i" from 0 to 360 step 30 do {
        private _testPos = _pos getPos [150, _i];
        private _testPosASL = AGLtoASL _testPos;
        
        if !(terrainIntersectASL [AGLtoASL _pos, _testPosASL]) then {
            _visibleArea = _visibleArea + 1;
        };
        
        // Verificar se o ponto tem cobertura traseira
        private _backPos = _pos getPos [5, _i + 180];
        if (lineIntersects [AGLtoASL _pos, AGLtoASL _backPos]) then {
            _concealment = _concealment + 1;
        };
    };
    
    // Se o ponto tiver boa visibilidade e alguma ocultação
    if (_visibleArea >= 8 && _concealment >= 4) then {
        _observationPoints pushBack [_pos, _visibleArea, _concealment];
    };
} forEach _highPoints;

// Retornar todos os dados analisados
[_highPoints, _coverPositions, _flankRoutes, _observationPoints]
