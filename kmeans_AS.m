%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [idx,C,D] = kmeans_AS(A,kmax,it,start,V)

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

% option d'initialisation : uniforme ou forcée? 
if ischar(start)
    if start=='uniform'
       for i=1:1:kmax 
            C(i,:)=A(ceil(rand*n),:);
       end
    end       
elseif isnumeric(start)
    CC=start;
    if isempty(kmax), kmax=size(CC,1);
    elseif kmax~=size(CC,1), error('The "start" matrix must have kmax rows.'); 
    elseif size(CC,2) ~=p, error('The “start” matrix must have the same nb of columns as A.');
    end
    C=CC;
end

idx=zeros(n,1);
idx2=zeros(n,1);

D=distfun(A,C,V);    		    	     
[E,idx]=min(D,[],2);
	   
for i = 1:it % do for desired # of attempts
  
    while any(idx~=idx2) % do as long as clustering changes
        idx2=idx;  
        
        Z=max(idx(:,ones(1,kmax))==ones(n,1)*linspace(1,kmax,kmax)); % find means actually used 
        for j=find(Z) % get new cluster means
            C(j,:)=mean(A(idx==j,:));
        end
        D=distfun(A,C,V);    		    	         
        [F,index]=min(D,[],1);
        for j=find(Z) % get new cluster means
            C(j,:)=A(index(j),:);
        end 	     
    end
    
    D=distfun(A,C,V);
[E,idx]=min(D,[],2);
   
end




