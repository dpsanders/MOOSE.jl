"""
    Read an XDA Mesh generated by libMesh
"""
function readXDAMesh(filename::String)

    startLog(main_perf_log, "readXDAMesh()")

    mesh = Mesh()

    # Set the sideset / nodeset numberings:
    boundary_info = mesh.boundary_info

    open(filename) do f
        lines = readlines(filename)

        lines = [split(line) for line in lines]

        current_line = 1

        # First line is a version number
        current_line += 1

        num_elem = parse(Int64, lines[current_line][1])
        current_line += 1

#        println("num_elem: ", num_elem)

        num_nodes = parse(Int64, lines[current_line][1])
        current_line += 1

#        println("num_nodes: ", num_elem)

        # BC file: 4
        current_line += 1
        # subdomain file: 5
        current_line += 1
        # proc file: 6
        current_line += 1
        # p-level file: 7
        current_line += 1
        # type size: 8
        current_line += 1
        # uid size: 9
        current_line += 1
        # pid size: 10
        current_line += 1
        # sid size: 11
        current_line += 1
        # p-level size: 12
        current_line += 1
        # eid size: 13
        current_line += 1
        # side size: 14
        current_line += 1
        # bid size: 15
        current_line += 1
        # subdomain to name map: 16
        current_line += 1

        num_elem_at_level_0 = parse(Int64, lines[current_line][1])
        current_line += 1

#        println("num_elem_at_level_0: ", num_elem_at_level_0)

        # The next lines are elements, but we don't want to read those yet
        elem_lines_start = current_line
        current_line += num_elem_at_level_0

        nodes = Array{Node}(num_nodes)

        # Let's read the nodes
        for node_id in 1:num_nodes
            x = parse(Float64, lines[current_line][1])
            y = parse(Float64, lines[current_line][2])

            node = Node{2}(node_id, Vec{2}((x,y)), [], invalid_processor_id)

            nodes[node_id] = node

            current_line += 1
        end

#        println(nodes)

        # NOW let's read the elements
        elements = Array{Element}(num_elem)

        for elem_id in 1:num_elem_at_level_0
            # Parse the line it is stored like this:
            # [ type sid (n0 ... nN-1) ]
            # All we need are the node IDs (but we need to transfer them to 1-based indexing
            node_ids = [parse(Int64, node_id) + 1 for node_id in lines[elem_lines_start + elem_id - 1][3:end]]

            element = Element(elem_id,
                              [nodes[node_id] for node_id in node_ids],
                              [],
                              invalid_processor_id)

            elements[elem_id] = element
        end

#        println(elements)

        # Unique ID presence
        current_line += 1
        # Sideset id to name map
        has_sideset_names = parse(Int64, lines[current_line][1])
        current_line += 1

        if has_sideset_names > 0
            # Vector length of sideset IDs with names
            current_line += 1

            # Sideset IDs: translate to 1-based
            sideset_ids = [parse(Int64, id) + 1 for id in lines[current_line]]
            current_line += 1

#            println("sideset_ids: ", sideset_ids)

            for bid in sideset_ids
                boundary_info.side_list[bid] = Array{ElemSidePair}(0)
            end

            # Vector length of sideset names
            current_line += 1

            # Sideset names (not currently used)
            sideset_names = lines[current_line]
            current_line += 1
        end

        num_side_bcs = parse(Int64, lines[current_line][1])
        current_line += 1

        # Read in the element/side pairs
        for i in 1:num_side_bcs
            data = [parse(Int64, val) + 1 for val in lines[current_line]]

            if !(data[3] in keys(boundary_info.side_list))
                boundary_info.side_list[data[3]] = Array{ElemSidePair}(0)
            end

            push!(boundary_info.side_list[data[3]], ElemSidePair(elements[data[1]], data[2]))

            current_line += 1
        end

        # Nodest id to name map
        has_nodeset_names = parse(Int64, lines[current_line][1])
        current_line += 1

        if has_nodeset_names > 0
            # Num nodesets with names
            current_line += 1

            nodeset_ids = [parse(Int64, id) + 1 for id in lines[current_line]]
            current_line += 1

#            println("nodeset_ids: ", nodeset_ids)

            for bid in nodeset_ids
                boundary_info.node_list[bid] = Array{Node}(0)
            end

            # Length of names
            current_line += 1

            # nodeset names (not currently used)
            nodeset_names = lines[current_line]
            current_line += 1
        end

        num_nodesets = parse(Int64, lines[current_line][1])
        current_line += 1

        for i in 1:num_nodesets
            data = [parse(Int64, val) + 1 for val in lines[current_line]]

            if !(data[2] in keys(boundary_info.node_list))
                boundary_info.node_list[data[2]] = Array{Node}(0)
            end

            push!(boundary_info.node_list[data[2]], nodes[data[1]])

            current_line += 1
        end

#        println("node_list: ", boundary_info.node_list)

        mesh.elements = elements
        mesh.nodes = nodes

        initialize!(mesh)
    end

    stopLog(main_perf_log, "readXDAMesh()")

    return mesh
end
