% [fittedRes, fittedVec] = fitEigvec(A, E, method, vals, vecs, win, numevals, weights)
% ~~~~~~~~~~~~~~~~~~~~~~~~
% ~~~~~~~~~INPUTS~~~~~~~~~
% ~~~~~~~~~~~~~~~~~~~~~~~~
% method = method type number one would like to use
% A = eigenvalue problem matrix
% vals = empirical eigenvalues
% vecs = empirical eigenvectors
% win = indices in which voltages can be read/inferred
% ~~~~~~~~~~~~~~~~~~~~~~~~~
% ~~~~~~~~~OUTPUTS~~~~~~~~~
% ~~~~~~~~~~~~~~~~~~~~~~~~~
% fittedVecs = fitted eigenvectors
% fittedRes = residuals from fittedVecs

function [fittedRes, fittedVec] = fitEigvec(A, method, vals, vecs, win)


I = eye(size(A));
rangerest = 1:length(A);
rangerest = rangerest(~ismember(rangerest, win));

for j = 1:length(vals)
    lambda = vals(j);
    Ashift = A-lambda*I;
    x1 = vecs(:,j);
    [fittedRes(j), fittedVec(:,j)] = calcResidual(method, Ashift, x1, win, rangerest);
end

end
%
% ~~~~~~~~~INPUTS~~~~~~~~~
%
% method = method type number one would like to use
% Ashift = matrix in question
% x1 = subset of eigenvector
% win = indices x1 is located on
% rangerest = indices of the rest of the eigenvector
% xfull = empty vector of size length(win) + length(rangerest)
% P = permutation matrix passed in for
%
% ~~~~~~~~~OUTPUTS~~~~~~~~~
%
% residual = calculated residual
% vec = full fitted eigenvector

function [residual, vec] = calcResidual(method, Ashift, x1, win, rangerest)
switch method
    case 'backward'
        [vs,sigma] = svds(Ashift',1,'smallest');
        x2 = vs(rangerest);
        ax1 = Ashift(:,win)*x1;
        ax2 = Ashift(:,rangerest)*x2;
        alpha = -(ax1'*ax2)/(ax1'*ax1);
        x = zeros(size(Ashift,1),1);
        x(win) = alpha*x1;
        x(rangerest) = x2;
        residual = norm(Ashift*x);
        vec = [x1; x2];
        
    case 'forward'
        [vs,sigma] = svds(Ashift',1,'smallest');
        vs_win = vs(win);
        vs_win = normalizematrix(vs_win);
        residual = 1 - abs(x1'*vs_win);
        vec = vs_win;

    case 'both'  % Constrained Fitting
        
        xfull = zeros(length(Ashift),1);
        Ifull = eye(length(Ashift));
        order = [win, rangerest];
        P = Ifull(order,:);
        Ashift = Ashift*ctranspose(P);
        
        % Form Intermediate Matrix
        T = zeros(length(Ashift),1+length(rangerest));
        T(1:length(win),1) = x1;
        T((length(win)+1):end,2:end) = eye(length(rangerest));
        G = Ashift*T;
        
        % Calculate smallest eigenvector and then form eigenvector
        [vs,alpha] = svds(G',1,'smallest');
        xfull(1:length(win)) = vs(1)*x1;
        xfull((length(win)+1):end) = vs(2:end);
        residual = norm(Ashift*xfull);
        vec = P'*xfull;
end
end