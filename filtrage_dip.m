%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                    %
%%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%%                        Equipes CERA & ENDV                         %
%%                                2011                                %
%%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% --------------------------------------------------------------------
% function [dataf,indf]=filtrage_dip(data,a)
%
% Filtrage basé sur la distance inter-points (dip)
%
% data : données dans base ACP
% a : défini la distance au signal le plus proche au-dessus de laquelle 
% un signal est considéré singulier. Si dip > a*dmoy (dmoy : distance
% moyenne au signal le plus proche), alors le signal est écarté.
%
% dataf : données filtrées
% indf : indices des données conservées (dans matrice de départ)
% --------------------------------------------------------------------

function [dataf,indf,Dmin,dmoy]=filtrage_dip(data,val_propres,a)

Dmin=zeros(size(data,1),1);

for i=1:size(data,1)
    D=distfun(data,data(i,:),val_propres);
    Ds=sort(D,'ascend');
    Dmin(i,1)=Ds(2);
end

dmoy=mean(Dmin);

indf=find(Dmin<(a*dmoy));
dataf=data(indf,:);