%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Si,MatSi,KSi]=silhouetteC(D,idx)

MatSi=zeros(size(D,1),1);
a=zeros(size(D,1),1);
b=zeros(size(D,1),1);

k=max(idx);
K=1:k;

for i=1:k
    a(idx==i,1)=D(idx==i,i);
    
    k2=K(K~=i);
    b(idx==i,1)=min(D(idx==i,k2),[],2);
end

MatSi(:,1)=(b-a)./max([a,b],[],2);

KSi=zeros(1,k);
for j=1:k
    KSi(1,j)=mean(MatSi(idx==j,1));
end

Si=mean(MatSi,1);