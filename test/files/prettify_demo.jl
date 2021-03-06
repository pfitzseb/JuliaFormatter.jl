function TetgenIO(
    points::Vector{Point{3,T}};
    pointattributes = SVector{0,T}[],
    pointmtrs = SVector{0,T}[],
    pointmarkers = Cint[],
    tetrahedrons = SimplexFace{4,Cint}[],
    tetrahedronattributes = T[],
    tetrahedronvolumes = T[],
    neighbors = Cint[],
    facets = JLFacet{T,Vector{Cint}}[],
    facetmarkers = Cint[],
    holes = Point{3,T}[],
    regions = Region{T}[],
    facetconstraints = FacetConstraint{inttype(T),T}[],
    segmentconstraints = SegmentationConstraint{inttype(T),T}[],
    trifaces = TriangleFace{Cint}[],
    trifacemarkers = Cint[],
    edges = LineFace{Cint}[],
    edgemarkers = Cint[]
) where T
    TetgenIO(
        points,
        pointattributes,
        pointmtrs,
        pointmarkers,
        tetrahedrons,
        tetrahedronattributes,
        tetrahedronvolumes,
        neighbors,
        facets,
        facetmarkers,
        holes,
        regions,
        facetconstraints,
        segmentconstraints,
        trifaces,
        trifacemarkers,
        edges,
        edgemarkers,
    )

end
