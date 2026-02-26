function SaveAllFigures(opt,filetype,basepath)

% opt: nom de base du fichier
% filetype: ex: 'fig'
% basepath: répertoire de sauvegarde

if nargin == 0
opt='Unknown';
end
if nargin < 2
filetype = 'fig';
end
pwd=basepath;
cd(pwd)
ChildList = sort(get(0,'Children'));
for cnum = 1:length(ChildList)
if strncmp(get(ChildList(cnum),'Type'),'figure',6)
saveas(ChildList(cnum), [opt, '_', num2str(ChildList(cnum)), '.' filetype]);
end
end
cd(basepath)

