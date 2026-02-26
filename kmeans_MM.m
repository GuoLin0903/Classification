%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [idx,C,D] = kmeans_MM(A,kmax,it,start,V)

%KMEANS k-means clustering
% 
% 	[idx,C,D] = kmeans_MM(A,kmax,iter,start,V)
% 
% k-means clustering of data vectors in A (n*p matrix). 
% A weighted (by the eigen values) squared euclidean distance is used. 
% kmax is the maximum number of desired clusters.
% iter is the desired number of clustering attempts. 
% If “start” = ‘uniform’, the clustering starts from a random 
% uniform initialisation. Else, “start” can be a (k*p) initialisation 
% matrix. 
% V is a row vector containing the eigen values. (default: ones(1,p))
% idx is a vector with cluster labels (1, .. , k) for each data point. 
% C is the clusters centres coordinates matrix (k*p).
% D is the point-to-cluster distance matrix (n*k).
%The clustering with the smallest sum of within cluster distances is returned.

[n,p]=size(A);
if nargin<5, V=ones(1,p); end

% option d'initialisation; uniforme ou forcée? 
if ischar(start)
    if start=='uniform'
        Amin=min(A,1);
        Amax=max(A,1) ;
    end
elseif isnumeric(start)
    CC=start;
    start='numeric';
    if isempty(kmax), kmax=size(CC,1);
    elseif kmax~=size(CC,1), error('The "start" matrix must have kmax rows.'); 
    elseif size(CC,2) ~=p, error('The “start” matrix must have the same nb of columns as A.');
    end
end

Jbest = inf;
idx=zeros(n,1);
for i = 1:it     						    % do for desired # of attempts
    k = kmax;						    % reset number of clusters
    if start=='uniform'				% get seeds for this attempt
        C = unifrnd(Amin(ones(k,1),:), Amax(ones(k,1),:));
    elseif start=='numeric'
        C=CC;
    end
    idx2=zeros(n,1);     					     % initialize clustering
    D=distfun(A,C,V);    		    	         % get distances between objects and seeds
    [E,idx]=min(D,[],2);     				      % find smallest distances and seeds
    while any(idx~=idx2)     				  % do as long as clustering changes
        idx2=idx;     						            % store previous clustering
        Z=max(idx(:,ones(1,k))==ones(n,1)*linspace(1,k,k));	% find means actually used 
        for j=find(Z)						           % get new cluster means
            C(j,:)=mean(A(find(idx==j),:));
        end
        C(~Z,:)=[];				                       % remove unused means
        k=sum(Z);				                    % adjust number of clusters
        D=distfun(A,C,V); 		    		     % get distances between objects and means
        [E,idx]=min(D,[],2);    		 	     % find smallest distances and clusters
    end
    J=0;
    for j=1:k				                            % use sum of within cluster distances
        J=J+sum(E(idx==j));
    end
    if J<Jbest     			                         % as a criterion; switch if better
        Ibest =idx;     			                  % store best clustering
        Cbest=C;
        Dbest=D;
        Jbest =J;     			                     % store best criterion value
    end
end
idx=Ibest;				                             % return best clustering
C=Cbest;
D=Dbest;



