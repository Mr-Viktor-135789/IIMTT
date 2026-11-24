function [E, nIter] = solveKepler(M, e, tol, maxIter)
%SOLVEKEPLER Решение уравнения Кеплера M = E - e*sin(E) методом Ньютона.

if nargin < 3
    tol = 1e-12;
end
if nargin < 4
    maxIter = 20;
end

E = M + e .* sin(M);
dE = inf(size(M));
nIter = 0;

while any(abs(dE(:)) > tol)
    nIter = nIter + 1;
    if nIter > maxIter
        warning('solveKepler: нет сходимости за %d итераций.', maxIter);
        break;
    end
    E_old = E;
    E = E + (M - E + e .* sin(E)) ./ (1 - e .* cos(E));
    dE = E - E_old;
end
end