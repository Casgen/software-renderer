#+feature dynamic-literals
package obj

TokenType :: enum {
    VertexPosition, // v
    VertexNormal, // vn
    VertexTexture, // vt
    PolygonFaceElement, // f
    VertexParameterSpace, // vp - Used for paramater-space objects (such as splines, cubic 3D surfaces, etc.)
    Object, // o
    Group, // g

    UseMaterial, // usemtl
    MaterialLibrary, // mtllib
    UseSmoothShading, // s

    FwdSlash,
    Number,
    LeftBracket,
    RightBracket,
    String,
    
    
    Illegal,
    EOF,
}


Token :: struct {
    type: TokenType,
    data: string,
}



keywords_map : map[string]TokenType = {
    "usemtl" = .UseMaterial,
    "mtllib" = .MaterialLibrary,
    "v" = .VertexPosition,
    "vn" = .VertexNormal,
    "vt" = .VertexTexture,
    "vp" = .VertexParameterSpace,
    "f" = .PolygonFaceElement,
    "o" = .Object,
    "g" = .Group,
    "usemtl" = .UseMaterial,
    "mtllib" = .MaterialLibrary,
    "s" = .UseSmoothShading,
}
