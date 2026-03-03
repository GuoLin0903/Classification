function AE_Cosmos_Main
% AE_Cosmos_Main
% -------------------------------------------------------------------------
% “AE Cosmos Lite” 主界面
%
% 依赖文件（保持原有工程不变）：
%   - AE_Tools_V3.m          : AIC / 事件定位等算法
%   - AE_Calc_Features.m     : 特征计算
%   - AE_Vis_TFD.m           : 时频图绘制
%   - AE_Logic_Filter.m      : 事件筛选逻辑
%   - AE_Utils.m             : 表格显示的工具函数
%   - waveReader.m           : 读取 .wave 文件
%
% 本文件新增：
%   - refine_late_events()   : 对 AIC 结果做统一“提前微调”的小后处理
%
% 使用方法：
%   >> AE_Cosmos_Main
%   在 GUI 中 Load .wave -> Calculate -> Apply filters -> 点击事件查看。
% -------------------------------------------------------------------------

%% ================== 1. 初始化数据结构 ==================
S = struct();
S.file           = '';      % 当前 .wave 文件路径
S.wave           = [];      % 原始波形  [Ns x Nch x Nevt]
S.fs             = [];      % 采样频率  (Hz)
S.eventTime      = [];      % 每个事件的 hittime
S.preTrigPoints  = [];      % pre-trigger 点数
S.A              = [];      % AIC 结果结构体（由 AE_Tools_V3 返回）
S.T              = [];      % 特征表
S.E              = table(); % 事件表（在左下角表格中展示）
S.selIdx         = [];      % 当前“筛选后”事件索引列表（指向所有事件）
S.selPos         = 1;       % 当前在 GUI 中选中的事件在 selIdx 中的序号
S.flags          = struct();% 一些布尔开关（doAIC / do99E 等）

% 实验几何 / 通道设置（根据你现在的配置）
S.chS1 = 1;    % 传感器 1 所在通道
S.chS2 = 3;    % 传感器 2 所在通道
S.L_mm = 120;  % 两传感器间距 (mm)
S.v_ms = 7338; % 波速 (m/s)

%% ================== 2. 搭建 GUI 布局 ==================
h.fig = figure('Name','AE Cosmos Lite UI (Modular, with t0 refine)', ...
               'Color','w','NumberTitle','off', ...
               'Position',[40 40 1720 960]);
set(h.fig,'DefaultAxesFontSize',11);

% ---- 左上：控制面板 ----
h.panCtrl = uipanel('Parent',h.fig,'Title','Controls','FontWeight','bold', ...
    'Units','normalized','Position',[0.01 0.54 0.32 0.43],'BackgroundColor',[1 1 1]);

% ---- 左下：事件表 ----
h.panTable = uipanel('Parent',h.fig,'Title','Events (click to view)', ...
    'Units','normalized','Position',[0.01 0.03 0.32 0.48],'BackgroundColor',[1 1 1]);

uicontrol(h.panTable,'Style','text','String','View:', ...
    'BackgroundColor',[1 1 1],'Units','normalized', ...
    'Position',[0.02 0.90 0.10 0.08],'HorizontalAlignment','left');


h.popView = uicontrol(h.panTable,'Style','popupmenu', ...
    'String',{'Mini','Standard'}, 'Value',1, ...
    'Units','normalized','Position',[0.12 0.90 0.22 0.08], ...
    'BackgroundColor',[1 1 1],'Callback',@onViewChange);

h.tbl = uitable(h.panTable,'Data',cell(0,1),'ColumnName',{'eventID'}, ...
    'Units','normalized','Position',[0.02 0.16 0.96 0.72], ...
    'CellSelectionCallback',@onTableClick,'ColumnEditable',false);

h.btnPrev = uicontrol(h.panTable,'Style','pushbutton','String','Prev', ...
    'Units','normalized','Position',[0.02 0.02 0.10 0.10],'Callback',@onPrev);

h.btnNext = uicontrol(h.panTable,'Style','pushbutton','String','Next', ...
    'Units','normalized','Position',[0.14 0.02 0.10 0.10],'Callback',@onNext);

% ---- 右侧：波形和频谱 ----
h.panPlot = uipanel('Parent',h.fig,'Title','Event preview (S1 & S2)', ...
    'Units','normalized','Position',[0.34 0.03 0.65 0.94],'BackgroundColor',[1 1 1]);

%% ---------------- 2.1 File & Status -------------------
h.secFile = uipanel('Parent',h.panCtrl,'Title','File & Status','BackgroundColor',[1 1 1], ...
    'Units','normalized','Position',[0.03 0.78 0.94 0.20]);

h.btnLoad = uicontrol(h.secFile,'Style','pushbutton','String','Load .wave', ...
    'Units','normalized','Position',[0.02 0.62 0.30 0.30],'Callback',@onLoad);

h.btnCalc = uicontrol(h.secFile,'Style','pushbutton','String','Calculate', ...
    'Units','normalized','Position',[0.34 0.62 0.30 0.30],'Callback',@onCalculate);

h.txtPath = uicontrol(h.secFile,'Style','edit','String','(none)','Enable','inactive','Max',2, ...
    'Units','normalized','Position',[0.02 0.34 0.96 0.22],'BackgroundColor',[1 1 1], ...
    'HorizontalAlignment','left');

h.txtStatus = uicontrol(h.secFile,'Style','text','String','Status: idle', ...
    'Units','normalized','Position',[0.02 0.08 0.64 0.22],'BackgroundColor',[1 1 1], ...
    'HorizontalAlignment','left');

h.txtSelected = uicontrol(h.secFile,'Style','text','String','Selected: 0 / 0', ...
    'Units','normalized','Position',[0.68 0.08 0.30 0.22],'BackgroundColor',[1 1 1], ...
    'HorizontalAlignment','right');

%% ---------------- 2.2 Modules (AIC / Features 等) ------
h.secMods = uipanel('Parent',h.panCtrl,'Title','Modules (toggle then press Calculate)', ...
    'BackgroundColor',[1 1 1],'Units','normalized','Position',[0.03 0.44 0.94 0.32]);

h.cbAIC = uicontrol(h.secMods,'Style','checkbox','String','AIC (Peak Backtrack)', ...
    'Units','normalized','Position',[0.02 0.70 0.46 0.22],'BackgroundColor',[1 1 1], ...
    'Value',1,'Callback',@onModsChange);

h.cbUse99E = uicontrol(h.secMods,'Style','checkbox','String','99% energy end', ...
    'Units','normalized','Position',[0.52 0.70 0.46 0.22],'BackgroundColor',[1 1 1], ...
    'Callback',@onModsChange);

h.cbLocate = uicontrol(h.secMods,'Style','checkbox','String','Localization (use v & L)', ...
    'Units','normalized','Position',[0.02 0.45 0.46 0.20],'BackgroundColor',[1 1 1], ...
    'Callback',@onModsChange);

h.cbFeat = uicontrol(h.secMods,'Style','checkbox','String','Compute features', ...
    'Units','normalized','Position',[0.52 0.45 0.46 0.20],'BackgroundColor',[1 1 1], ...
    'Callback',@onModsChange);

uicontrol(h.secMods,'Style','text','String','Features from','BackgroundColor',[1 1 1], ...
    'Units','normalized','Position',[0.02 0.25 0.30 0.12],'HorizontalAlignment','left');

h.popFeatSrc = uicontrol(h.secMods,'Style','popupmenu', ...
    'String',{'Raw full record','Segmented (AIC→99E)'}, 'Value',1, ...
    'Units','normalized','Position',[0.34 0.25 0.64 0.14],'BackgroundColor',[1 1 1], ...
    'Callback',@onModsChange);

uicontrol(h.secMods,'Style','text','String','TFD Visualization:', ...
    'Units','normalized','Position',[0.02 0.05 0.30 0.12], ...
    'BackgroundColor',[1 1 1], 'HorizontalAlignment','left', 'FontWeight','bold');

h.btnTFD = uicontrol(h.secMods,'Style','pushbutton','String','Compute TFD (Current Event)', ...
    'Units','normalized','Position',[0.34 0.02 0.64 0.18], ...
    'Callback',@onRunTFD);

%% ---------------- 2.3 Feature filters ------------------
h.panFilt = uipanel('Parent',h.panCtrl,'Title','Feature filters (after Calculate)', ...
    'BackgroundColor',[1 1 1],'Units','normalized','Position',[0.03 0.06 0.94 0.34]);

mklabel(h.panFilt,[0.02 0.78 0.20 0.18],'t_min (s)');     h.edTmin  = mkedit(h.panFilt,[0.24 0.78 0.20 0.18], 0);
mklabel(h.panFilt,[0.52 0.78 0.20 0.18],'RT_max (us)');   h.edRTmax = mkedit(h.panFilt,[0.74 0.78 0.20 0.18], inf);
mklabel(h.panFilt,[0.02 0.56 0.20 0.18],'x_min (mm)');    h.edXmin  = mkedit(h.panFilt,[0.24 0.56 0.20 0.18], -inf);
mklabel(h.panFilt,[0.52 0.56 0.20 0.18],'x_max (mm)');    h.edXmax  = mkedit(h.panFilt,[0.74 0.56 0.20 0.18], inf);
mklabel(h.panFilt,[0.02 0.34 0.20 0.18],'Amp_min (dB)');  h.edAmin  = mkedit(h.panFilt,[0.24 0.34 0.20 0.18], -inf);
mklabel(h.panFilt,[0.52 0.34 0.20 0.18],'Amp_max (dB)');  h.edAmax  = mkedit(h.panFilt,[0.74 0.34 0.20 0.18], inf);
mklabel(h.panFilt,[0.02 0.12 0.20 0.18],'FC_min (kHz)');  h.edFCmin = mkedit(h.panFilt,[0.24 0.12 0.20 0.18], -inf);
mklabel(h.panFilt,[0.52 0.12 0.20 0.18],'FC_max (kHz)');  h.edFCmax = mkedit(h.panFilt,[0.74 0.12 0.20 0.18], inf);

h.cbS1 = uicontrol(h.panFilt,'Style','checkbox','String','Use S1','Value',1, ...
    'BackgroundColor',[1 1 1],'Units','normalized','Position',[0.02 0.00 0.15 0.12]);
h.cbS2 = uicontrol(h.panFilt,'Style','checkbox','String','Use S2','Value',1, ...
    'BackgroundColor',[1 1 1],'Units','normalized','Position',[0.18 0.00 0.15 0.12]);
% 新增：Export WEASEL 按钮（使用当前筛选后的事件）
h.btnExportWeasel = uicontrol(h.panFilt,'Style','pushbutton','String','Export WEASEL', ...
    'Units','normalized','Position',[0.52 0.00 0.20 0.12], ...
    'Callback',@onExportWeasel);
h.btnApply = uicontrol(h.panFilt,'Style','pushbutton','String','Apply filters', ...
    'Units','normalized','Position',[0.74 0.00 0.20 0.12],'Callback',@onApply);

%% ---------------- 2.4 右边 6 个坐标轴 -------------------
h.axS1t  = axes('Parent',h.panPlot,'Units','normalized','Position',[0.07 0.70 0.40 0.24]); grid(h.axS1t,'on'); box(h.axS1t,'on');
h.axS2t  = axes('Parent',h.panPlot,'Units','normalized','Position',[0.53 0.70 0.40 0.24]); grid(h.axS2t,'on'); box(h.axS2t,'on');

h.axS1f  = axes('Parent',h.panPlot,'Units','normalized','Position',[0.07 0.43 0.40 0.18]); grid(h.axS1f,'on'); box(h.axS1f,'on');
h.axS2f  = axes('Parent',h.panPlot,'Units','normalized','Position',[0.53 0.43 0.40 0.18]); grid(h.axS2f,'on'); box(h.axS2f,'on');

h.axS1tf = axes('Parent',h.panPlot,'Units','normalized','Position',[0.07 0.08 0.40 0.28]); grid(h.axS1tf,'on'); box(h.axS1tf,'on');
h.axS2tf = axes('Parent',h.panPlot,'Units','normalized','Position',[0.53 0.08 0.40 0.28]); grid(h.axS2tf,'on'); box(h.axS2tf,'on');

linkaxes([h.axS1t h.axS2t],'x');
linkaxes([h.axS1f h.axS2f],'x');

%% 把句柄和状态存入 guidata
guidata(h.fig, struct('h',h,'S',S));

onModsChange();   % 初始化一些 Enable 状态
drawCurrent();    % 清空图

%% ================== 3. 回调函数 ======================

    function onLoad(~,~)
        % 加载 .wave 文件
        [f,p] = uigetfile('*.wave','Select AE .wave file');
        if isequal(f,0), return; end

        st = guidata(h.fig);
        st.S.file = fullfile(p,f);
        set(h.txtPath,'String',st.S.file);
        set(h.txtStatus,'String','Status: reading .wave ...'); drawnow;

        try
            [~, wave, ~, ~, eventTime, ~, fs, ~, ~, ~, ~, ~, preTrigPoints] = waveReader(st.S.file);
        catch
            errordlg('waveReader.m not found or failed.','File Error');
            return;
        end

        st.S.wave          = double(wave);
        st.S.fs            = fs;
        st.S.eventTime     = eventTime(:);
        st.S.preTrigPoints = preTrigPoints;

        nEv = size(wave,3);
        Ns  = size(wave,1);

        % 创建最基本的事件表（只有 ID / hittime / k0 / kE）
        E = table((1:nEv)','VariableNames',{'eventID'});
        E.hittime = st.S.eventTime;
        E.k0      = ones(nEv,1);
        E.kE      = Ns * ones(nEv,1);

        st.S.E      = E;
        st.S.selIdx = (1:nEv)';
        st.S.selPos = 1;
        st.S.A      = [];
        st.S.T      = table();
        st.S.flags  = struct();

        guidata(h.fig,st);

        refreshTableDynamic(E, h.fig);
        set(h.txtSelected,'String',sprintf('Selected: %d / %d', numel(st.S.selIdx), nEv));
        set(h.txtStatus,'String',sprintf('Status: file loaded. %d events.',nEv));

        updateFilterEnable(h.fig);
        drawCurrent();
    end

    function onCalculate(~,~)
        % 主计算：AIC / 99% 能量 / 特征
        st = guidata(h.fig);
        if isempty(st.S.wave)
            errordlg('Please Load a .wave file first.','No data');
            return;
        end

        set(h.txtStatus,'String','Status: calculating ...'); drawnow;

        doAIC  = (get(h.cbAIC,'Value')   == 1);
        do99E  = (get(h.cbUse99E,'Value')== 1);
        doLoc  = (get(h.cbLocate,'Value')== 1);
        doFeat = (get(h.cbFeat,'Value')  == 1);
        featSrc = get(h.popFeatSrc,'Value');

        wave = st.S.wave;
        fs   = st.S.fs;
        preTrigPoints = st.S.preTrigPoints;

        chS1 = st.S.chS1;
        chS2 = st.S.chS2;
        L_mm = st.S.L_mm;
        v_ms = st.S.v_ms;

        [Ns,~,nEv] = size(wave);

        A      = struct();
        hasAIC = false;

        % ---------- 3.1 运行 AIC ----------
        if doAIC
            set(h.txtStatus,'String','Status: AIC picking ...'); drawnow;
            CH_struct  = struct('S1',chS1,'S2',chS2);
            GEO_struct = struct('L_mm',L_mm,'v_ms',v_ms);

            C = struct();
            C.thr_main_factor = 7;
            C.dt_rel_margin   = 0.2;
            C.deep_all        = true;
            C.RefineFcn       = [];   % 不在 AE_Tools 里 refine，在外面统一做

            try
                A = AE_Tools_V3.pick_all_events_hybrid( ...
                        wave, fs, CH_struct, preTrigPoints, GEO_struct, C);
                hasAIC = true;

                % ---- 统一做一次“t0 提前微调” ----
                if isfield(A,'idx') && isfield(A,'t0_S1_us') && isfield(A,'t0_S2_us')
                    [A.idx, A.t0_S1_us, A.t0_S2_us] = refine_late_events( ...
                        wave, fs, preTrigPoints, CH_struct, ...
                        A.idx, A.t0_S1_us, A.t0_S2_us);
                end

            catch ME
                msg = sprintf('AIC picking failed:\n%s', ME.message);
                errordlg(msg,'AIC Error');
                rethrow(ME);
            end
        end

        st.S.A = A;

        % ---------- 3.2 根据 AIC / 99% 能量 计算 k0 / kE ----------
        prepad = round(20e-6 * fs);   % 在 AIC 前多留 20 µs

        if hasAIC && isfield(A,'idx') && ~isempty(A.idx)
            k0_all = min(A.idx,[],2);             % S1 / S2 最早的一个点
            k0_all(isnan(k0_all)) = preTrigPoints+1;
            k0_all = max(1, k0_all - prepad);
        else
            k0_all = max(1, preTrigPoints - round(50e-6*fs)) * ones(nEv,1);
        end

        if do99E
            xsum_all = sum(double(wave(:,[chS1 chS2],:)).^2,2);
            xsum_all = squeeze(xsum_all);  % [Ns x Nevt]
            kE_all   = nan(nEv,1);
            for ev = 1:nEv
                kE_all(ev) = AE_Tools_V3.find_end_by_energy( ...
                                xsum_all(:,ev), fs, k0_all(ev), 0.99);
            end
        else
            kE_all = Ns * ones(nEv,1);
        end

        kE_all = max(kE_all, k0_all);
        kE_all = min(kE_all, Ns);

        % ---------- 3.3 构造事件表 E ----------
        E = table((1:nEv)','VariableNames',{'eventID'});
        E.hittime = st.S.eventTime;
        E.k0      = k0_all;
        E.kE      = kE_all;

        if hasAIC && isfield(A,'t0_S1_us')
            E.t0_S1_us = A.t0_S1_us(:);
            E.t0_S2_us = A.t0_S2_us(:);
        else
            E.t0_S1_us = nan(nEv,1);
            E.t0_S2_us = nan(nEv,1);
        end

        if doLoc && hasAIC && isfield(A,'x_mm')
    E.x_mm = A.x_mm(:);

    % ====== (NEW) 定位是否有效 + 时间差（用于判近传感器）======
    if isfield(A,'valid')
        E.loc_valid = logical(A.valid(:));
    else
        E.loc_valid = isfinite(E.x_mm);
    end

    if isfield(A,'dt_us')
        E.dt_us = A.dt_us(:);                 % dt_us = t0_S2 - t0_S1
    else
        % 兜底：由 t0 重算（单位 us）
        E.dt_us = E.t0_S2_us - E.t0_S1_us;
    end
else
    % 没做定位时，保持字段存在，后面逻辑更稳
    E.x_mm      = nan(nEv,1);
    E.loc_valid = false(nEv,1);
    E.dt_us     = nan(nEv,1);
        end


        % ---------- 3.4 特征计算 ----------
        if doFeat
            if doAIC && do99E
                featSrc = 2;    % 如果已经有 k0 / kE，则强制使用分段
            end

            if featSrc == 1
                k0_tmp = ones(nEv,1);
                kE_tmp = Ns * ones(nEv,1);
            else
                k0_tmp = k0_all;
                kE_tmp = kE_all;
            end

            set(h.txtStatus,'String',sprintf('Status: features on %d events ...',nEv)); drawnow;

            [Tfull, E] = AE_Calc_Features.run_and_merge( ...
                            wave, fs, chS1, chS2, ...
                            st.S.eventTime, k0_tmp, kE_tmp, ...
                            E, hasAIC);
            st.S.T = Tfull;
        else
            st.S.T = table();
        end

        % ---------- 3.5 更新状态并刷新表格 ----------
        st.S.flags = struct('doAIC',doAIC,'do99E',do99E);
        st.S.E     = E;
        st.S.selIdx = (1:nEv)';
        st.S.selPos = 1;

        guidata(h.fig,st);

        refreshTableDynamic(E, h.fig);
        updateFilterEnable(h.fig);
        set(h.txtSelected,'String',sprintf('Selected: %d / %d', nEv, nEv));
        set(h.txtStatus,'String','Status: calculation done. Press "Apply filters".');

        drawCurrent();
    end

    function onApply(~,~)
        % 应用左下角的各种筛选条件
        st = guidata(h.fig);
        if isempty(st.S.E), return; end

        st = applyFilters(st);
        guidata(h.fig,st);

        updateFilterEnable(h.fig);
        drawCurrent();
    end

    function st = applyFilters(st)
        % 真正执行筛选逻辑（调用 AE_Logic_Filter.apply）
        E = st.S.E;
        nEv = height(E);

        F.tmin  = get_safe_double(h.edTmin,  -inf);
        F.xmin  = get_safe_double(h.edXmin,  -inf);
        F.xmax  = get_safe_double(h.edXmax,   inf);
        F.rtmax = get_safe_double(h.edRTmax,  inf);
        F.amin  = get_safe_double(h.edAmin,  -inf);
        F.amax  = get_safe_double(h.edAmax,   inf);
        F.fcmin = get_safe_double(h.edFCmin, -inf);
        F.fcmax = get_safe_double(h.edFCmax,  inf);
        F.useS1 = (get(h.cbS1,'Value')==1);
        F.useS2 = (get(h.cbS2,'Value')==1);

        mask = AE_Logic_Filter.apply(E, F);
        st.S.validMask = mask;
        st.S.selIdx = find(mask);
        st.S.selPos = 1;

        refreshTableDynamic(E(mask,:), h.fig);
        set(h.txtSelected,'String',sprintf('Selected: %d / %d', numel(st.S.selIdx), nEv));
        set(h.txtStatus,'String',sprintf('Status: %d / %d events selected', numel(st.S.selIdx), nEv));
    end

    function val = get_safe_double(hObj, defVal)
        str = get(hObj,'String');
        if isempty(str)
            val = defVal;
        else
            val = str2double(str);
            if isnan(val), val = defVal; end
        end
    end

    function onTableClick(~,evt)
        % 表格点击，更新当前 selPos
        if isempty(evt.Indices), return; end
        st = guidata(h.fig);
        row = evt.Indices(1);

        if isempty(st.S.selIdx) || row > numel(st.S.selIdx), return; end
        st.S.selPos = row;
        guidata(h.fig,st);
        drawCurrent();
    end

    function onPrev(~,~)
        st = guidata(h.fig);
        if isempty(st.S.selIdx), return; end
        st.S.selPos = max(1, st.S.selPos - 1);
        guidata(h.fig,st);
        drawCurrent();
    end

    function onNext(~,~)
        st = guidata(h.fig);
        if isempty(st.S.selIdx), return; end
        st.S.selPos = min(numel(st.S.selIdx), st.S.selPos + 1);
        guidata(h.fig,st);
        drawCurrent();
    end

    function onModsChange(~,~)
        % 勾选“Compute features” 时才允许改 feature 来源
        set(h.popFeatSrc,'Enable', tern(get(h.cbFeat,'Value')==1,'on','off'));
    end

    function onRunTFD(~,~)
        % 对当前事件计算 TFR（调用 AE_Vis_TFD）
        st = guidata(h.fig);
        if isempty(st.S.wave) || isempty(st.S.selIdx), return; end

        idx = st.S.selIdx(st.S.selPos);
        fs  = st.S.fs;
        w   = st.S.wave;

        s1 = double(w(:, st.S.chS1, idx));
        s2 = double(w(:, st.S.chS2, idx));

        set(h.txtStatus,'String','Status: Computing TFD ...'); drawnow limitrate;

        AE_Vis_TFD.draw(h.axS1tf, s1, fs);
        title(h.axS1tf,'Spectrogram (S1)');

        AE_Vis_TFD.draw(h.axS2tf, s2, fs);
        title(h.axS2tf,'Spectrogram (S2)');

        set(h.txtStatus,'String','Status: TFD Done.');
    end

    function onViewChange(~,~)
        % Mini / Standard 两种表格视图切换
        st = guidata(h.fig);
        if isempty(st.S.E), return; end

        if isempty(st.S.selIdx)
            Eview = st.S.E;
        else
            Eview = st.S.E(st.S.selIdx,:);
        end
        refreshTableDynamic(Eview, h.fig);
    end

    function drawCurrent()
        % 右侧所有图的刷新：波形 + FFT + 蓝线/红线
        st = guidata(h.fig);

        cla(h.axS1t); cla(h.axS2t);
        cla(h.axS1f); cla(h.axS2f);
        cla(h.axS1tf); cla(h.axS2tf);

        if isempty(st.S.wave) || isempty(st.S.selIdx)
            return;
        end

        wave = st.S.wave;
        fs   = st.S.fs;
        ch1  = st.S.chS1;
        ch2  = st.S.chS2;
        idxEv = st.S.selIdx(st.S.selPos);
        Ns   = size(wave,1);

        s1 = double(wave(:, ch1, idxEv));
        s2 = double(wave(:, ch2, idxEv));
        tt = (0:Ns-1)'/fs*1e6;     % us

        % ---- Time domain ----
        plot(h.axS1t, tt, s1, 'k-','LineWidth',1.0);
        grid(h.axS1t,'on'); box(h.axS1t,'on');
        xlabel(h.axS1t,'Time (\mus)');
        ylabel(h.axS1t,'V');
        title(h.axS1t,sprintf('Event %d  S1', idxEv));

        plot(h.axS2t, tt, s2, 'k-','LineWidth',1.0);
        grid(h.axS2t,'on'); box(h.axS2t,'on');
        xlabel(h.axS2t,'Time (\mus)');
        ylabel(h.axS2t,'V');
        title(h.axS2t,sprintf('Event %d  S2', idxEv));

        % ---- 标出 t0 和结束点 ----
        if ismember('t0_S1_us', st.S.E.Properties.VariableNames)
            t1 = st.S.E.t0_S1_us(idxEv);
            t2 = st.S.E.t0_S2_us(idxEv);
            if isfinite(t1), xline(h.axS1t, t1, 'b--','LineWidth',1.1); end
            if isfinite(t2), xline(h.axS2t, t2, 'b--','LineWidth',1.1); end
        end
        if ismember('kE', st.S.E.Properties.VariableNames)
            tE = (st.S.E.kE(idxEv)-1)/fs*1e6;
            xline(h.axS1t, tE, 'r--','LineWidth',1.1);
            xline(h.axS2t, tE, 'r--','LineWidth',1.1);
        end

        % ---- FFT ----
        f_view_max = 1200;  % kHz
        NFFT = 2^nextpow2(max(Ns,512));
        fHz  = (fs/2) * linspace(0,1,NFFT/2+1)';

        Y1 = abs(fft(s1,NFFT));
        Y1 = Y1(1:NFFT/2+1);
        if max(Y1) > 0, Y1 = Y1 / max(Y1); end

        plot(h.axS1f, fHz/1e3, Y1, 'k-','LineWidth',1.0);
        xlim(h.axS1f,[0 min((fs/2)/1e3, f_view_max)]);
        grid(h.axS1f,'on'); box(h.axS1f,'on');
        xlabel(h.axS1f,'Frequency (kHz)');
        ylabel(h.axS1f,'Norm Mag');

        Y2 = abs(fft(s2,NFFT));
        Y2 = Y2(1:NFFT/2+1);
        if max(Y2) > 0, Y2 = Y2 / max(Y2); end

        plot(h.axS2f, fHz/1e3, Y2, 'k-','LineWidth',1.0);
        xlim(h.axS2f,[0 min((fs/2)/1e3, f_view_max)]);
        grid(h.axS2f,'on'); box(h.axS2f,'on');
        xlabel(h.axS2f,'Frequency (kHz)');
        ylabel(h.axS2f,'Norm Mag');

        % 时频图在 onRunTFD 时计算，这里保持空白
    end
end   % ======= AE_Cosmos_Main 结束 =======


%% ================== 4. 子函数（与 GUI 解耦） ==================

function refreshTableDynamic(E, fig)
% 根据当前视图模式 (Mini / Standard) 刷新左下角表格
if nargin < 2 || isempty(fig) || ~ishandle(fig)
    fig = gcf;
end
st = guidata(fig);
if isempty(st) || ~isfield(st,'h') || ~isfield(st.h,'tbl') || ~isgraphics(st.h.tbl)
    return;
end

modeVal = 1;
if isfield(st.h,'popView') && isgraphics(st.h.popView)
    modeVal = get(st.h.popView,'Value');
end

cols = AE_Utils.get_view_columns(E, modeVal);
C    = AE_Utils.table2cell_ui(E(:,cols));
set(st.h.tbl,'Data',C,'ColumnName',cols);
end


function updateFilterEnable(fig)
% 目前只做简单处理：所有 filter 都可用
if nargin < 1 || isempty(fig) || ~ishandle(fig)
    fig = gcf;
end
st = guidata(fig);
if isempty(st) || ~isfield(st,'h'), return; end
h = st.h;
hList = [h.edAmin,h.edAmax,h.edFCmin,h.edFCmax,h.edRTmax,h.cbS1,h.cbS2];
hList = hList(isgraphics(hList));
set(hList,'Enable','on');
end


function mklabel(p,pos,str)
uicontrol(p,'Style','text','String',str,'BackgroundColor',[1 1 1], ...
    'HorizontalAlignment','left','Units','normalized','Position',pos);
end


function h = mkedit(p,pos,val)
h = uicontrol(p,'Style','edit','String',num2str(val),'BackgroundColor',[1 1 1], ...
    'Units','normalized','Position',pos);
end


function out = tern(cond,a,b)
if cond, out = a; else, out = b; end
end



%==================================================================
% 导出当前筛选后的事件到 WEASEL
%   对 S1 / S2 各生成一个文件：
%       xxx_WEASEL_S1_data.mat / xxx_WEASEL_S2_data.mat
%   data_loc 列：
%       col 1 : time  （hittime, s）
%       col 2 : channel （对应 S.chS1 或 S.chS2）
%       col 3:end : 该传感器的一组特征（去掉 S1_/S2_ 前缀给 WEASEL）
%==================================================================
function onExportWeasel(~,~)
    try
        st = guidata(gcf);
        if isempty(st) || ~isfield(st,'S') || isempty(st.S.E)
            warning('WEASEL export: S.E is empty.');
            return;
        end

        Eall = st.S.E;

        % 1) 取筛选后的 mask（如果没筛选过就全选）
        if isfield(st.S,'validMask') && ~isempty(st.S.validMask)
            mask = st.S.validMask;
        else
            mask = true(height(Eall),1);
        end

        if ~any(mask)
            fprintf('>>> WEASEL export skipped: 0 events after filters.\n');
            return;
        end

        % 2) 看看界面上 S1 / S2 勾选与否（没拿到控件就默认都导出）
        useS1 = true;
        useS2 = true;
        if isfield(st,'h')
            if isfield(st.h,'cbS1') && isgraphics(st.h.cbS1)
                useS1 = get(st.h.cbS1,'Value')==1;
            end
            if isfield(st.h,'cbS2') && isgraphics(st.h.cbS2)
                useS2 = get(st.h.cbS2,'Value')==1;
            end
        end

        % 3) 对 S1 / S2 分别导出
        if useS1
            weasel_export_one_sensor(st, mask, 'S1');
        end
        if useS2
            weasel_export_one_sensor(st, mask, 'S2');
        end

    catch ME
        warning('WEASEL export failed: %s', ME.message);
    end
    % 4) (NEW) 导出 Near-sensor 矩阵：仅定位有效事件 + 每事件自动选近传感器特征
weasel_export_near_sensor(st, mask);

    
end  % onExportWeasel


%------------------------------------------------------------------
% 实际导出一个传感器的特征
%   sensorTag = 'S1' 或 'S2'
%------------------------------------------------------------------
function weasel_export_one_sensor(st, mask, sensorTag)

    Eall = st.S.E;
    E    = Eall(mask,:);

    if isempty(E)
        fprintf('>>> WEASEL export(%s): 0 events.\n', sensorTag);
        return;
    end

    % ---------- time 列 ----------
    if ismember('hittime', E.Properties.VariableNames)
        time_vec = E.hittime(:);
    else
        error('WEASEL export(%s): table S.E 中找不到变量 ''hittime''', sensorTag);
    end

    % ---------- channel 列 ----------
    if ismember('channel', E.Properties.VariableNames)
        ch_vec = E.channel(:);
    else
        if strcmpi(sensorTag,'S1') && isfield(st.S,'chS1')
            ch_val = st.S.chS1;
        elseif strcmpi(sensorTag,'S2') && isfield(st.S,'chS2')
            ch_val = st.S.chS2;
        else
            error('WEASEL export(%s): 无法确定通道号（缺少 S.chS1 / S.chS2 或列 channel）', sensorTag);
        end
        ch_vec = repmat(ch_val, height(E), 1);
    end

    % ---------- 固定顺序的特征名（不含 S1_/S2_ 前缀） ----------
    featShort = { ...
        'Amp_dB','Dur_us','Energy_V2','ZCR_pct', ...
        'RiseTime_us','TempCentroid_us','alpha', ...
        'PP2_1','PP2_2','PP2_3','PP2_4', ...
        'FC_kHz','PF_kHz','SSpread_kHz','SSkew', ...
        'SKurt','SSlope','SRoff_kHz', ...
        'SsqrtSpreadP_kHz','SSkewP','SKurtP','SRon_kHz', ...
        'WPE1','WPE2','WPE3','WPE4', ...
        'WPE5','WPE6','WPE7','WPE8', ...
        'Entropy' ...
    };

    % 带前缀的真实列名，例如 'S1_Amp_dB' 或 'S2_Amp_dB'
    featFull = strcat(sensorTag, '_', featShort);

    % 只保留在表里真实存在的列
    featNames = featFull(ismember(featFull, E.Properties.VariableNames));

    if isempty(featNames)
        fprintf('>>> WEASEL export(%s): no %s_* features.\n', sensorTag, sensorTag);
        return;
    end

    % ---------- 特征矩阵 ----------
    feat_mat = E{:, featNames};   % N x nFeat

    % ---------- 组装 data_loc：[time, channel, features...] ----------
    data_loc = [time_vec, ch_vec, feat_mat];

    % ---------- 输出路径 ----------
    [waveFolder, waveBase, ~] = fileparts(st.S.file);
    if isempty(waveFolder)
        waveFolder = pwd;
    end

    outMat   = fullfile(waveFolder, sprintf('%s_WEASEL_%s_data.mat',     waveBase, sensorTag));
    listFile = fullfile(waveFolder, sprintf('%s_WEASEL_%s_features.txt', waveBase, sensorTag));

    save(outMat, 'data_loc');

    % ---------- 写特征名列表（去掉 S1_/S2_ 前缀） ----------
    fid = fopen(listFile, 'w');
    if fid ~= -1
        fprintf(fid, 'col_index\tvar_name\n');

        % 前两列是元信息
        fprintf(fid, '%d\t%s\n', 1, 'time_s');
        fprintf(fid, '%d\t%s\n', 2, 'channel');

        for jj = 1:numel(featNames)
            shortName = featNames{jj};
            if strncmp(shortName,'S1_',3) || strncmp(shortName,'S2_',3)
                shortName = shortName(4:end);
            end
            fprintf(fid, '%d\t%s\n', jj+2, shortName);
        end
        fclose(fid);
    end

    fprintf('>>> WEASEL export(%s): %s (data_loc: %d events x %d columns)\n', ...
            sensorTag, outMat, size(data_loc,1), size(data_loc,2));
    fprintf('>>> Feature list(%s): %s\n', sensorTag, listFile);
end

%------------------------------------------------------------------
% (NEW) 导出 Near-sensor 特征矩阵：
%   - 只使用定位有效（E.loc_valid==true）的事件
%   - 每个事件根据 dt_us 自动判断 near sensor（S1 or S2）
%   - 输出一个文件：xxx_WEASEL_NEAR_data.mat / xxx_WEASEL_NEAR_features.txt
%   data_loc 列：
%       col 1 : time  （hittime, s）
%       col 2 : channel（每事件对应近传感器通道号）
%       col 3:end : 近传感器的一组特征（不带 S1_/S2_ 前缀）
%------------------------------------------------------------------
function weasel_export_near_sensor(st, mask)

    Eall = st.S.E;
    E    = Eall(mask,:);

    if isempty(E)
        fprintf('>>> WEASEL export(NEAR): 0 events after filters.\n');
        return;
    end

    % 必要列检查
    needVars = {'hittime','dt_us','loc_valid'};
    for k = 1:numel(needVars)
        if ~ismember(needVars{k}, E.Properties.VariableNames)
            error('WEASEL export(NEAR): S.E 缺少变量 "%s"。请先按补丁把 dt_us/loc_valid 写入 E。', needVars{k});
        end
    end
    if ~isfield(st.S,'chS1') || ~isfield(st.S,'chS2')
        error('WEASEL export(NEAR): 缺少 st.S.chS1 / st.S.chS2（用于输出 channel 列）');
    end

    % 只保留定位有效事件
    ok = E.loc_valid==true & isfinite(E.dt_us);
    E  = E(ok,:);
    if isempty(E)
        fprintf('>>> WEASEL export(NEAR): 0 events with loc_valid==true.\n');
        return;
    end

    time_vec = E.hittime(:);

    % 判近传感器：dt_us = t2 - t1
    % dt_us > 0 -> S1 更早到达 -> 更靠近 S1
    isS1near = (E.dt_us > 0);
    isS2near = (E.dt_us < 0);

    % dt==0 兜底：用更大幅值判近（你也可以改成固定归 S1）
    isZero = ~(isS1near | isS2near);
    if any(isZero)
        a1 = nan(height(E),1); a2 = nan(height(E),1);
        if ismember('S1_Amp_dB', E.Properties.VariableNames), a1 = E.S1_Amp_dB; end
        if ismember('S2_Amp_dB', E.Properties.VariableNames), a2 = E.S2_Amp_dB; end
        isS1near(isZero) = a1(isZero) >= a2(isZero);
        isS2near(isZero) = ~isS1near(isZero);
    end

    % channel 列（每事件对应 near sensor 的通道号）
    ch_vec = nan(height(E),1);
    ch_vec(isS1near) = st.S.chS1;
    ch_vec(isS2near) = st.S.chS2;

    % 特征列表（与你现有 weasel_export_one_sensor 保持一致）
    featShort = { ...
        'Amp_dB','Dur_us','Energy_V2','ZCR_pct', ...
        'RiseTime_us','TempCentroid_us','alpha', ...
        'PP2_1','PP2_2','PP2_3','PP2_4', ...
        'FC_kHz','PF_kHz','SSpread_kHz','SSkew', ...
        'SKurt','SSlope','SRoff_kHz', ...
        'SsqrtSpreadP_kHz','SSkewP','SKurtP','SRon_kHz', ...
        'WPE1','WPE2','WPE3','WPE4', ...
        'WPE5','WPE6','WPE7','WPE8', ...
        'Entropy' ...
    };

    % 确保 S1_ / S2_ 都存在的特征才导出（避免缺列崩）
    s1Cols = strcat('S1_', featShort);
    s2Cols = strcat('S2_', featShort);
    keep   = ismember(s1Cols, E.Properties.VariableNames) & ismember(s2Cols, E.Properties.VariableNames);

    featShort = featShort(keep);
    s1Cols    = s1Cols(keep);
    s2Cols    = s2Cols(keep);

    if isempty(featShort)
        fprintf('>>> WEASEL export(NEAR): no common S1_*/S2_* feature columns.\n');
        return;
    end

    % 逐列拼接 “near-feature matrix”
    nEv   = height(E);
    nFeat = numel(featShort);
    feat_mat = nan(nEv, nFeat);

    for j = 1:nFeat
        v1 = E{:, s1Cols{j}};
        v2 = E{:, s2Cols{j}};
        feat_mat(isS1near, j) = v1(isS1near);
        feat_mat(isS2near, j) = v2(isS2near);
    end

    data_loc = [time_vec, ch_vec, feat_mat];

    % 输出路径
    [waveFolder, waveBase, ~] = fileparts(st.S.file);
    if isempty(waveFolder), waveFolder = pwd; end

    outMat   = fullfile(waveFolder, sprintf('%s_WEASEL_NEAR_data.mat',     waveBase));
    listFile = fullfile(waveFolder, sprintf('%s_WEASEL_NEAR_features.txt', waveBase));

    save(outMat, 'data_loc');

    fid = fopen(listFile, 'w');
    if fid ~= -1
        fprintf(fid, 'col_index\tvar_name\n');
        fprintf(fid, '%d\t%s\n', 1, 'time_s');
        fprintf(fid, '%d\t%s\n', 2, 'channel');
        for jj = 1:numel(featShort)
            fprintf(fid, '%d\t%s\n', jj+2, featShort{jj});
        end
        fclose(fid);
    end

    fprintf('>>> WEASEL export(NEAR): %s (data_loc: %d events x %d columns)\n', ...
            outMat, size(data_loc,1), size(data_loc,2));
    fprintf('>>> Feature list(NEAR): %s\n', listFile);
end


%% ================== 5. AIC 后处理：统一提前 t0 ==================

function [idx_new, t0_S1_us_new, t0_S2_us_new] = refine_late_events( ...
    wave, fs, preTrigPoints, CH, idx_old, t0_S1_us_old, t0_S2_us_old)
% refine_late_events
% -------------------------------------------------------------------------
% 目的：解决 “AIC 普遍偏晚，错过第一个波峰” 的问题。
%
% 思路（两通道完全相同）：
%   1. 在 pre-trigger 后的若干窗口内，先估计噪声 std，再取整段的最大幅值；
%   2. 设置阈值 thr = max( thrSigma * noiseStd , thrRel * maxAmp );
%   3. 从 preTrigPoints+1 往后扫描，找到第一段
%        “连续 >= thr 且持续时间 >= minDur_us”
%      的起点记为 kCand；
%   4. 若 kCand 比旧的 AIC (k_old) 提前，且提前量 <= maxShift_us，
%      则把 t0 更新到 kCand；否则保持原来的 AIC 不变。
%
% 这样可以：
%   - 统一“往前找第一个大于噪声阈值的波”，
%   - 又不会把所有 t0 一股脑地提前太多。
% -------------------------------------------------------------------------

[Ns,~,Nevt] = size(wave);

idx_new      = idx_old;
t0_S1_us_new = t0_S1_us_old;
t0_S2_us_new = t0_S2_us_old;

% 可调参数
thrSigma   = 5.0;   % 噪声倍数阈值
thrRel     = 0.08;  % 相对幅度阈值 (占全段最大幅度的比例)
minDur_us  = 5;     % 连续超过阈值的最小持续时间
maxShift_us = 200;  % 单次最多允许提前 200 µs
maxSearch_us = 500; % 从 pre-trigger 往后最多搜索 500 µs

minDur_samp   = max(1, round(minDur_us   * 1e-6 * fs));
maxShift_samp =        round(maxShift_us * 1e-6 * fs);
maxSearch_samp=        round(maxSearch_us* 1e-6 * fs);

fprintf('>>> refine_late_events is running...\n');

for ev = 1:Nevt
    for ic = 1:2

        % -------- 通道选择 --------
        if ic == 1
            ch = CH.S1;
        else
            ch = CH.S2;
        end
        if ch < 1 || ch > size(wave,2)
            continue;
        end

        s = double(wave(:,ch,ev));
        if isempty(s) || all(~isfinite(s))
            continue;
        end

        % -------- 噪声估计（pre-trigger 前后 50 µs） --------
        kN2 = min(max(1, preTrigPoints), Ns);
        kN1 = max(1, kN2 - round(50e-6 * fs));
        noiseSeg = s(kN1:kN2);
        if isempty(noiseSeg)
            continue;
        end
        noiseStd = std(noiseSeg);
        if ~(isscalar(noiseStd) && isfinite(noiseStd) && noiseStd > 0)
            continue;
        end

        % -------- 后段最大幅值 --------
        kSearch1 = min(Ns, preTrigPoints + 1);
        kSearch2 = min(Ns, preTrigPoints + maxSearch_samp);
        if kSearch1 > kSearch2
            continue;
        end
        segPost = s(kSearch1:kSearch2);
        if isempty(segPost)
            continue;
        end
        maxAmp = max(abs(segPost));
        if ~(isfinite(maxAmp) && maxAmp > 0)
            continue;
        end

        % 阈值
        thr = max(thrSigma * noiseStd, thrRel * maxAmp);

        % -------- 构造“超过阈值”掩码，并找第一段连续超阈值 --------
        mask = abs(s) >= thr;
        mask(1:preTrigPoints) = false;  % pre-trigger 内不算

        runLen = 0;
        kCand  = NaN;
        for k = kSearch1:kSearch2
            if mask(k)
                runLen = runLen + 1;
                if runLen >= minDur_samp
                    kCand = k - runLen + 1;
                    break;
                end
            else
                runLen = 0;
            end
        end

        if isnan(kCand)
            % 找不到合适起点，保持原 AIC
            continue;
        end

        % -------- 和旧 AIC 比较，决定是否更新 --------
        k_old = idx_old(ev,ic);
        if ~(isfinite(k_old) && k_old >= 1 && k_old <= Ns)
            continue;
        end

        % 只允许“往前移动”
        if kCand >= k_old
            continue;
        end

        shift_samp = k_old - kCand;
        if shift_samp <= 0 || shift_samp > maxShift_samp
            continue;
        end

        % 通过所有检查：接受新起点
        idx_new(ev,ic) = kCand;
        t_us = (kCand - preTrigPoints) / fs * 1e6;
        if ic == 1
            t0_S1_us_new(ev) = t_us;
        else
            t0_S2_us_new(ev) = t_us;
        end
    end
end

nModified = sum(any(idx_new ~= idx_old, 2));
fprintf('>>> refine_late_events: %d events modified\n', nModified);
end
