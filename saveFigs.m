function saveFigs(formats)
    % SAVEFIGS 批量保存所有打开的 Figure 窗口
    % 输入参数:
    %   formats: 字符数组或元胞数组，例如 'png' 或 {'png', 'fig', 'pdf'}
    %   如果不输入参数，默认保存 png 和 fig
    
    if nargin < 1
        formats = {'png', 'fig'}; % 默认格式
    end
    
    % 确保 formats 是元胞数组格式
    if ischar(formats) || isstring(formats)
        formats = {char(formats)};
    end

    % 获取所有窗口
    allFigs = findall(0, 'Type', 'figure');
    if isempty(allFigs)
        fprintf('警告: 当前没有检测到任何打开的 Figure 窗口。\n');
        return;
    end

    % 创建保存路径：当前文件夹下的 Saved_Results 子文件夹
    mainFolder = 'Saved_Results';
    subFolder = datestr(now, 'yyyy-mm-dd_HHMMSS');
    targetPath = fullfile(mainFolder, subFolder);
    
    if ~exist(targetPath, 'dir')
        mkdir(targetPath);
    end

    fprintf('开始导出 %d 个窗口到: %s\n', length(allFigs), targetPath);

    for i = 1:length(allFigs)
        h = allFigs(i);
        figName = sprintf('Figure_%d', h.Number);
        fullBaseName = fullfile(targetPath, figName);
        
        % 根据选择的格式进行保存
        for f = 1:length(formats)
            fmt = lower(formats{f});
            switch fmt
                case 'fig'
                    savefig(h, [fullBaseName '.fig']);
                case 'png'
                    exportgraphics(h, [fullBaseName '.png'], 'Resolution', 300);
                case 'jpg'
                    exportgraphics(h, [fullBaseName '.jpg'], 'Resolution', 300);
                case 'pdf'
                    exportgraphics(h, [fullBaseName '.pdf'], 'ContentType', 'vector');
                case 'eps'
                    exportgraphics(h, [fullBaseName '.eps']);
                otherwise
                    fprintf('跳过未知格式: %s\n', fmt);
            end
        end
        fprintf('  [✓] %s 已处理\n', figName);
    end
    
    % 保存完成后自动打开文件夹（Windows系统常用）
    if ispc
        winopen(targetPath);
    end
    fprintf('所有操作已完成！\n');
end