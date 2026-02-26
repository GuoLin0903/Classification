%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2012                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [axis]=intitule(axe)

if axe > 12
    axis = num2str(axe);
else
    switch axe
        case 1
            axis='Temps de montée (\mus)';
        case 2
            axis='Amplitude (dB)';
        case 3
            axis='Fréquence moyenne (kHz)';
        case 4
            axis='Nombre de coups au pic';
        case 5
            axis='Fréquence de reverberation (kHz)';
        case 6
            axis='Fréquence d''initiation (kHz)';
        case 7
            axis='Energie (attoJ)';
        case 8
            axis='A/M (dB/\mus)';
        case 9
            axis='E/A (attoJ/dB)';
        case 10
            axis='Amplitude/fréquence (dB/kHz)'; 
        case 11
            axis='Barycentre fréquenciel (kHz)'; % axis='Paramétrique 2 (23)'; 
        case 12
            axis='Fréquence au pic (kHz)'; 
    end    
end

end