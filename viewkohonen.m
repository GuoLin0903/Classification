%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function graf=viewkohonen(poids,inpt);

% < function graf=viewkohonen(poids,inpt) >
%
% --- *** --- *** ---
%
% Trace les activations des neurones d'une carte de Kohonen représentée par "poids", pour
% les données de "inpt" (générées par make_input ou make_randinput)
%
% --- *** --- *** ---

[lninpt m]=size(poids);
dim=floor(sqrt(m));
[lninpt n]=size(inpt);
compdist=zeros(1,m);
graf=zeros(dim,dim);

indices=ones(2,m);
com=1;
for i=1:dim
   for j=1:dim
      indices(1,com)=i;
      indices(2,com)=j;
      com=com+1;
   end
end
dist=zeros(1,m);

for i=1:lninpt
   tempinpt=inpt(i,:);
   for com=1:m
      dist(com)=sum((tempinpt'-poids(:,com)).^2);
   end   
   compdist=compdist+dist;
   [onsenfout,mine]=min(dist);
   icoor=indices(1,mine);jcoor=indices(2,mine);
   graf(icoor,jcoor)=graf(icoor,jcoor)+1;
end

figure;
rotate3d on;
graf=abs(graf);
mesh(graf);
axis([1 dim 1 dim]);
xlabel('j');
ylabel('i');

graf2=zeros(dim,dim);
for i=1:m
   graf2(indices(1,i),indices(2,i))=sum(compdist(i));
end
graf2=1./graf2;
graf2=abs(graf2);
figure;
surf(graf2);
shading interp;
rotate3d on;