
function [count] = Calc(idx,nb_c)
idc=nb_c;
[n,p]=size(idx);
j=1;
count=0;
Numero=zeros(3655,1);
for i=1:n
    Variable=idx(i,1);
    if Variable==idc
        Numero(j,1)=i;
        j=j+1;
        count=count+1;
    end
end

Num=Numero(1:j-1,1);
count;


return