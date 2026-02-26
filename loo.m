%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2012                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hit = loo(data,idx,K)

%% Leave-one-out cross validation

% Determine K for KNN clustering

% Input:
%
% data: data matrix for cross validation
% idx: signals membership
% K: vector of K values to be evaluated
%

hit = zeros(size(data,1),length(K));

ind = cumsum(ones(size(data,1),1));

for i=1:size(data,1)

        ind2 = setxor(i,ind);

        [~,~,hit(i,:)] = fknn(data(ind2,:),idx(ind2),data(i,:),idx(i),K,0);
        
end


clear ind i j ind2