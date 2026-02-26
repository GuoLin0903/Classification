%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function graphe_cont(data,desc_graphe,type_desc)

switch nargin
    case 1 %Tracé dans base des CP
        desc_graphe = 1:size(data,2);
        type_desc = 2;
    case 2 %Tracé des desc AEwin
        type_desc = 0;
end

nb_d = size(desc_graphe,2);
nb_subplot = nb_d*(nb_d-1)/2;
tailleA = ceil(sqrt(nb_subplot));
tailleB = ceil(nb_subplot/tailleA);
ref_graphe = 1;

for ref_composante = 1:nb_d-1;
    ref_comp_2 = ref_composante+1;
    axe1 = desc_graphe(ref_composante);
    while ref_comp_2<nb_d+1;
        axe2 = desc_graphe(ref_comp_2);
        subplot(tailleB,tailleA,ref_graphe)
        plot(data(:,axe1),data(:,axe2),'.')
        switch type_desc
            case 0 %Tracé des desc AEwin
                xlabel(intitule(axe1))
                ylabel(intitule(axe2))
            case 1 %Tracé des desc recalculés
                xlabel(intitule_WFfeat(axe1))
                ylabel(intitule_WFfeat(axe2))
            case 2 %Tracé dans base des CP
                xlabel(['CP ' num2str(axe1)])
                ylabel(['CP ' num2str(axe2)])  
        end
        ref_graphe = ref_graphe+1;
        ref_comp_2 = ref_comp_2+1;
    end
end