%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 %DISTFUN Calculate point to cluster centroid distances.
function D = distfun(A,C,V)
[n,p]=size(A);
if nargin<3 || isempty(V)==1, V=ones(1,p); end
D=zeros(n,size(C,1)); 
for i=1:size(C,1)
    D(:,i)=sqrt(sum(V(repmat(1,n,1),:).*((A-C(repmat(i,n,1),:)).^2), 2));
end
 
