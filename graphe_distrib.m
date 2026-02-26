%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                    %
%%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%%                        Equipes CERA & ENDV                         %
%%                                2011                                %
%%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% --------------------------------------------------------------------
% function graphe_distrib(data,type_desc)
%
% Tracé des fonctions de distributions par descripteur
% Donne pour indication la position de la médiane par rapport à la
% distribution et le coefficient de détermination calculé par rapport 
% à une distribution normale de mêmes moyenne et écart-type
%
% data : n signaux x d desc
% type_desc : [0] Desc AEwin ; [1] Desc recalculés
% --------------------------------------------------------------------

function graphe_distrib(data,type_desc)

if isempty(type_desc)==1
    type_desc = 0;
end

%% Calcul du rapport (médiane-P5)/(P95-P5) pour application du ln

stat=prctile(data,[5 50 95]);
rapport=(stat(2,:)-stat(1,:))./(stat(3,:)-stat(1,:));


%% Tracé
switch type_desc
    case 0 % Pour 18 descripteurs AEwin
    for i=1:2
        figure;
        for j=1:9
            axe1=(9*i-8)+(j-1);
            subplot(3,3,j)
            dataj=sort(data(:,axe1),'ascend');

            Pe=cumsum(ones(size(dataj,1),1))./sum(ones(size(dataj,1),1));

            datalim=dataj(Pe>0.05 & Pe<0.95);
            mu=median(datalim);
            sigma=std(datalim);
            P=normcdf(dataj,mu,sigma);

            SCT=sum((P(P>0.05 & P<0.95)-0.5).^2);
            SCE=sum((Pe(Pe>0.05 & Pe<0.95)-0.5).^2);
            R2=SCE/SCT;

            plot(dataj,Pe,'.')
            hold on
            plot(dataj,P,'-r')
            grid on
            box off
            xlabel(intitule(axe1))
            ylabel('P(X<x)')
            ylim([0.05 0.95])
            title(['Pos. méd. : ' num2str(rapport(axe1),'%10.2f') ' - R^2 : ' num2str(R2,'%10.2f')])
        end 
    end

    case 1 % Pour 30 descripteurs calculés sur formes d'onde
        % Desc temporels
        figure
        for j=1:7
            subplot(3,3,j)
            dataj=sort(data(:,j),'ascend');

            Pe=cumsum(ones(size(dataj,1),1))./sum(ones(size(dataj,1),1));

            datalim=dataj(Pe>0.05 & Pe<0.95);
            mu=median(datalim);
            sigma=std(datalim);
            P=normcdf(dataj,mu,sigma);

            SCT=sum((P(P>0.05 & P<0.95)-0.5).^2);
            SCE=sum((Pe(Pe>0.05 & Pe<0.95)-0.5).^2);
            R2=SCE/SCT;

            plot(dataj,Pe,'.')
            hold on
            plot(dataj,P,'-r')
            grid on
            box off
            xlabel(intitule_WFfeat(j))
            ylabel('P(X<x)')
            ylim([0.0 0.95])
            title(['Pos. méd. : ' num2str(rapport(j),'%10.2f') ' - R^2 : ' num2str(R2,'%10.2f')])
        end
        
        % Desc spectraux 1
        figure
        for j=8:13
            subplot(2,3,j-7)
            dataj=sort(data(:,j),'ascend');

            Pe=cumsum(ones(size(dataj,1),1))./sum(ones(size(dataj,1),1));

            datalim=dataj(Pe>0.05 & Pe<0.95);
            mu=median(datalim);
            sigma=std(datalim);
            P=normcdf(dataj,mu,sigma);

            SCT=sum((P(P>0.05 & P<0.95)-0.5).^2);
            SCE=sum((Pe(Pe>0.05 & Pe<0.95)-0.5).^2);
            R2=SCE/SCT;

            plot(dataj,Pe,'.')
            hold on
            plot(dataj,P,'-r')
            grid on
            box off
            xlabel(intitule_WFfeat(j))
            ylabel('P(X<x)')
            ylim([0.0 0.95])
            title(['Pos. méd. : ' num2str(rapport(j),'%10.2f') ' - R^2 : ' num2str(R2,'%10.2f')])
        end
        
        % Desc spectraux 2
        figure
        for j=14:22
            subplot(3,3,j-13)
            dataj=sort(data(:,j),'ascend');

            Pe=cumsum(ones(size(dataj,1),1))./sum(ones(size(dataj,1),1));

            datalim=dataj(Pe>0.05 & Pe<0.95);
            mu=median(datalim);
            sigma=std(datalim);
            P=normcdf(dataj,mu,sigma);

            SCT=sum((P(P>0.05 & P<0.95)-0.5).^2);
            SCE=sum((Pe(Pe>0.05 & Pe<0.95)-0.5).^2);
            R2=SCE/SCT;

            plot(dataj,Pe,'.')
            hold on
            plot(dataj,P,'-r')
            grid on
            box off
            xlabel(intitule_WFfeat(j))
            ylabel('P(X<x)')
            ylim([0.0 0.95])
            title(['Pos. méd. : ' num2str(rapport(j),'%10.2f') ' - R^2 : ' num2str(R2,'%10.2f')])
        end
             

%% Desc ondelettes  Modified by Lin to adapte COSMOS Feat
nd = size(data,2);   
figure
for j = 23:nd
    subplot(3,3,j-22)   % j=23..31 
    dataj=sort(data(:,j),'ascend');

    Pe=cumsum(ones(size(dataj,1),1))./sum(ones(size(dataj,1),1));

    datalim=dataj(Pe>0.05 & Pe<0.95);
    mu=median(datalim);
    sigma=std(datalim);
    P=normcdf(dataj,mu,sigma);

    SCT=sum((P(P>0.05 & P<0.95)-0.5).^2);
    SCE=sum((Pe(Pe>0.05 & Pe<0.95)-0.5).^2);
    R2=SCE/SCT;

    plot(dataj,Pe,'.')
    hold on
    plot(dataj,P,'-r')
    grid on
    box off
    xlabel(intitule_WFfeat(j))
    ylabel('P(X<x)')
    ylim([0.0 0.95])
    title(['Pos. méd. : ' num2str(rapport(j),'%10.2f') ...
           ' - R^2 : ' num2str(R2,'%10.2f')])
end
   
%         % Desc ondelettes
%         figure
%         for j=23:30
%             subplot(3,3,j-22)
%             dataj=sort(data(:,j),'ascend');
% 
%             Pe=cumsum(ones(size(dataj,1),1))./sum(ones(size(dataj,1),1));
% 
%             datalim=dataj(Pe>0.05 & Pe<0.95);
%             mu=median(datalim);
%             sigma=std(datalim);
%             P=normcdf(dataj,mu,sigma);
% 
%             SCT=sum((P(P>0.05 & P<0.95)-0.5).^2);
%             SCE=sum((Pe(Pe>0.05 & Pe<0.95)-0.5).^2);
%             R2=SCE/SCT;
% 
%             plot(dataj,Pe,'.')
%             hold on
%             plot(dataj,P,'-r')
%             grid on
%             box off
%             xlabel(intitule_WFfeat(j))
%             ylabel('P(X<x)')
%             ylim([0.0 0.95])
%             title(['Pos. méd. : ' num2str(rapport(j),'%10.2f') ' - R^2 : ' num2str(R2,'%10.2f')])
%         end
end


