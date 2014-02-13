function cellout = mycellfun(varargin)
cellout = cellfun(varargin{:}, 'UniformOutput', false); %how can I pass multiple outputs through cellout?
end