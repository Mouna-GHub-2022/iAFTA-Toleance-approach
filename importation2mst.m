% Load clustering and network initialization result from file
load('wsn_results.mat');

% Choose one cluster for testing GA replacement algorithm
clusterIdx = 2; % Change this to the index of the cluster you want to test
clusterNodes = nodes(idx == clusterIdx, :); % Get nodes belonging to the chosen cluster
clusterCH = cell2mat(best_solutions(clusterIdx)); % Get the current CH of the chosen cluster

% Initialize downed CH
downed_CH = clusterCH;

% Maximum number of generations
max_generations = 600;

% Initialize population
population_size = 5;
population = randi([1, size(clusterNodes, 1)], population_size, size(clusterNodes, 1));

% Fitness function
fitness_function = @(pop) calculate_fitness(pop, clusterNodes, clusterCH);

% Initialize variables to store the best solution and its fitness
best_solution = [];
best_fitness = -Inf;

% Initialize fitness history
fitness_history = zeros(max_generations, 1);

% Visualization
figure;
xlabel('Generation');
ylabel('Fitness Value');
title('Fitness Value vs. Generation');

for generation = 1:max_generations
    % Evaluate fitness of each individual in the population
    fitness_values = fitness_function(population);
    
    % Find the best solution in the current population
    [current_best_fitness, index] = max(fitness_values);
    current_best_solution = population(index, :);
    
    % Update the best solution and its fitness
    if current_best_fitness > best_fitness
        best_fitness = current_best_fitness;
        best_solution = current_best_solution;
    end
    
    % Update fitness history
    fitness_history(generation) = best_fitness;
    
    % Visualization
    plot(1:generation, fitness_history(1:generation), 'b');
    xlabel('Generation');
    ylabel('Fitness Value');
    title('Fitness Value vs. Generation');
    hold on;
    pause(0.005);
    
    % Select parents for crossover (tournament selection)
    num_parents = 2;
    parents = zeros(num_parents, size(clusterNodes, 1));
    for i = 1:num_parents
        tournament = randi(population_size, 1, 2);
        [~, idx] = max(fitness_values(tournament));
        parents(i, :) = population(tournament(idx), :);
    end
    
    % Perform crossover (single-point crossover)
    crossover_point = randi([1, size(clusterNodes, 1) - 1]);
    offspring = zeros(population_size, size(clusterNodes, 1));
    for i = 1:2:population_size
        parent1 = parents(mod(i, num_parents) + 1, :);
        parent2 = parents(mod(i + 1, num_parents) + 1, :);
        offspring(i, :) = [parent1(1:crossover_point), parent2(crossover_point+1:end)];
        offspring(i + 1, :) = [parent2(1:crossover_point), parent1(crossover_point+1:end)];
    end
    
    % Perform mutation (randomly select a node and change it to a random node)
    mutation_rate = 0.1;
    for i = 1:population_size
        if rand < mutation_rate
            mutation_point = randi(size(clusterNodes, 1));
            offspring(i, mutation_point) = randi(size(clusterNodes, 1));
        end
    end
    
    % Update population with offspring
    population = offspring;
end

% Display the best solution and its fitness
fprintf('Best solution: Node %d\n', best_solution(1));
fprintf('Best fitness value: %.4f\n', best_fitness);

% Visualize network with only the best solution
figure;
scatter(clusterNodes(:, 1), clusterNodes(:, 2), 'filled');
hold on;
scatter(clusterNodes(best_solution(1), 1), clusterNodes(best_solution(1), 2), 'r', 'filled');
scatter(clusterCH(1), clusterCH(2), 'k', 'filled');
text(clusterNodes(:, 1) + 0.01, clusterNodes(:, 2) + 0.01, num2str((1:size(clusterNodes, 1))'));
text(clusterCH(1) + 0.01, clusterCH(2) + 0.01, 'Cluster Head');
text(clusterNodes(best_solution(1), 1) + 0.01, clusterNodes(best_solution(1), 2) + 0.01, 'Selected Node');
xlabel('X-coordinate');
ylabel('Y-coordinate');
title('Network Visualization (Best Solution)');
legend('Nodes', 'Selected Node', 'Cluster Head', 'Location', 'Best');
axis equal;

% Step 4: Construct MST for CHs and Sink node using Kruskal's Algorithm
% Replace the downed CH with the new CH generated by GA
new_CH = clusterNodes(best_solution(1), :);
best_solutions{clusterIdx} = num2cell(new_CH); % Update best_solutions with the new CH

% Compute MST
MST_edges = kruskal_mst(best_solutions, sink_node);

% Plot final network including all nodes, CHs, Sink, and MST edges
figure;
hold on;

% Plot all nodes
scatter(nodes(:, 1), nodes(:, 2), 'filled', 'MarkerFaceColor', 'k');

% Plot CHs and Sink for each cluster with different colors
colors = hsv(optimal_k); % Generate a set of colors for each cluster
for i = 1:optimal_k
    clusterNodes = nodes(idx == i, :);
    scatter(clusterNodes(:, 1), clusterNodes(:, 2), 'filled', 'MarkerFaceColor', colors(i, :));
    ch_coords = best_solutions{i}; % Get CH coordinates
    
    % Check if ch_coords is a cell array
    if iscell(ch_coords)
        scatter(ch_coords{1}, ch_coords{2}, 100, 'filled', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', colors(i, :)); % Plot CHs
    else
        scatter(ch_coords(1), ch_coords(2), 100, 'filled', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', colors(i, :)); % Plot CHs
    end
end

% Plot new CH
scatter(new_CH(1), new_CH(2), 200, '', 'filled', 'MarkerEdgeColor', 'k'); % Plot new CH
text(new_CH(1) + 2, new_CH(2) + 2, 'New CH', 'Color', colors(1, :)); % Label new CH

% Plot downed CH
scatter(downed_CH(1), downed_CH(2), 200, 'b', 'filled', 'MarkerEdgeColor', 'k'); % Plot downed CH
text(downed_CH(1) + 2, downed_CH(2) + 2, 'Downed CH', 'Color', 'b'); % Label downed CH

% Plot Sink
scatter(sink_node(1), sink_node(2), 200, 'g', 'filled', 'MarkerEdgeColor', 'k');
text(sink_node(1) + 2, sink_node(2) + 2, 'Sink', 'Color', 'g');

% Plot MST edges
for i = 1:size(MST_edges, 1)
    plot(MST_edges(i, [1, 3]), MST_edges(i, [2, 4]), 'b-', 'LineWidth', 1.5);
end

xlabel('X-coordinate');
ylabel('Y-coordinate');
title('Final Network Visualization');
grid on;
axis equal;



% Fitness function
function fitness = calculate_fitness(node, node_coordinates, clusterCH)
    population_size = size(node, 1);
    num_nodes = size(node, 2);
    fitness = zeros(population_size, 1);
    for j = 1:population_size
        for i = 1:num_nodes
            if node(j, i) == find(ismember(node_coordinates, clusterCH, 'rows'))
                % Penalize the solution if it selects the current CH
                fitness(j) = fitness(j) - 1000;
            else
                distance_to_CH = norm(node_coordinates(node(j, i), :) - clusterCH);
                distance_to_others = sum(sqrt(sum((node_coordinates - node_coordinates(node(j, i), :)).^2, 2)));
                fitness(j) = fitness(j) + 1 / (1 + distance_to_CH + distance_to_others);
            end
        end
    end
end

% Kruskal's MST function
function MST_edges = kruskal_mst(best_solutions, sink_node)
    % Convert cell array to matrix for easier handling
    CH_XY = [];
    for i = 1:length(best_solutions)
        if iscell(best_solutions{i})
            CH_XY = [CH_XY; cell2mat(best_solutions{i})];
        else
            CH_XY = [CH_XY; best_solutions{i}];
        end
    end
    CH_XY = [CH_XY; sink_node]; % Add sink node to the list of CHs

    % Number of CHs including the sink node
    numCH = size(CH_XY, 1);

    % Create edge list with distances
    edgeList = [];
    for i = 1:numCH
        for j = i+1:numCH
            distance = norm(CH_XY(i, :) - CH_XY(j, :));
            edgeList = [edgeList; i, j, distance];
        end
    end

    % Sort edge list by distance
    edgeList = sortrows(edgeList, 3);

    % Initialize MST edges and disjoint set
    MST_edges = [];
    parent = 1:numCH;
    rank = zeros(1, numCH);

    % Find function for disjoint set
    function root = find(x)
        if parent(x) ~= x
            parent(x) = find(parent(x));
        end
        root = parent(x);
    end

    % Union function for disjoint set
    function union(x, y)
        rootX = find(x);
        rootY = find(y);
        if rootX ~= rootY
            if rank(rootX) > rank(rootY)
                parent(rootY) = rootX;
            elseif rank(rootX) < rank(rootY)
                parent(rootX) = rootY;
            else
                parent(rootY) = rootX;
                rank(rootX) = rank(rootX) + 1;
            end
        end
    end

    % Kruskal's algorithm to construct MST
    numEdges = 0;
    i = 1;
    while numEdges < numCH - 1
        node1 = edgeList(i, 1);
        node2 = edgeList(i, 2);
        if find(node1) ~= find(node2)
            MST_edges = [MST_edges; CH_XY(node1, :), CH_XY(node2, :)];
            union(node1, node2);
            numEdges = numEdges + 1;
        end
        i = i + 1;
    end
end







