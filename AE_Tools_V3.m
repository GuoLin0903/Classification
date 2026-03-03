classdef AE_Tools_V3
    % AE_Tools_V3
    %  - pick_all_events_hybrid : AIC+Deep Hunt 早起点拾取（与 UI/AE_Cosmos_Main 对接）
    %  - pick_all_events_energy : 能量比例法（兼容老脚本）
    %  - find_end_by_energy     : 99% 能量结束点
    %  - 其它函数为内部工具：AIC、几何定位等

    methods(Static)

        %% ======================= 1. 混合 AIC 拾取（UI 使用） =======================
        function RES = pick_all_events_hybrid(wave, fs, CH, preTrigPoints, GEO, C)
            % wave: [Ns x Nch x Nev]
            % CH  : struct('S1',ch1,'S2',ch2)
            % GEO : struct('L_mm',L_mm,'v_ms',v_ms)
            % C   : 可选配置，常用字段：
            %       .thr_main_factor (默认 8)
            %       .deep_all        (默认 false)
            %       .dt_rel_margin   (默认 0.2, 暂未使用)
            % 输出 RES:
            %   .t0_S1_us, .t0_S2_us, .dt_us, .x_mm, .valid, .idx, .nPicked

            C = AE_Tools_V3.fill_defaults(C, fs);

            Ns   = size(wave,1);
            Nev  = size(wave,3);

            t0_S1_us = nan(Nev,1);
            t0_S2_us = nan(Nev,1);
            dt_us    = nan(Nev,1);
            x_mm     = nan(Nev,1);
            valid    = false(Nev,1);
            idx      = nan(Nev,2);

            for ev = 1:Nev
                s1 = double(wave(:, CH.S1, ev));
                s2 = double(wave(:, CH.S2, ev));

                % ---- 1) 每个通道各自做一次稳健 AIC ----
                [k1, t1_us, k_thr1] = AE_Tools_V3.pick_one_robust( ...
                    s1, fs, preTrigPoints, C.thr_main_factor);
                [k2, t2_us, k_thr2] = AE_Tools_V3.pick_one_robust( ...
                    s2, fs, preTrigPoints, C.thr_main_factor);

                % ---- 2) 可选 Deep Hunt：沿阈值前向回看 S0 早起点 ----
                if C.deep_all && isfinite(k_thr1)
                    k1 = AE_Tools_V3.pick_one_deep_hunt(s1, fs, k_thr1, preTrigPoints);
                    t1_us = (k1-1)/fs*1e6;
                end
                if C.deep_all && isfinite(k_thr2)
                    k2 = AE_Tools_V3.pick_one_deep_hunt(s2, fs, k_thr2, preTrigPoints);
                    t2_us = (k2-1)/fs*1e6;
                end

                % 防御性检查：索引必须在 [1,Ns]
                if ~(isfinite(k1) && k1>=1 && k1<=Ns), k1 = NaN; t1_us = NaN; end
                if ~(isfinite(k2) && k2>=1 && k2<=Ns), k2 = NaN; t2_us = NaN; end

                idx(ev,:) = [k1, k2];

                if isfinite(k1) && isfinite(k2)
                    t0_S1_us(ev) = t1_us;
                    t0_S2_us(ev) = t2_us;
                    dt_us(ev)    = t2_us - t1_us;

                    if nargin >= 5 && ~isempty(GEO) && isfield(GEO,'L_mm') ...
                                    && isfield(GEO,'v_ms')
                        [x_mm(ev), valid(ev)] = AE_Tools_V3.geo_from_dt(dt_us(ev), GEO);
                    else
                        valid(ev) = true;
                    end
                else
                    if isfinite(k1), t0_S1_us(ev) = t1_us; end
                    if isfinite(k2), t0_S2_us(ev) = t2_us; end
                    x_mm(ev)  = NaN;
                    valid(ev) = false;
                end
            end

            RES = struct();
            RES.t0_S1_us = t0_S1_us;
            RES.t0_S2_us = t0_S2_us;
            RES.dt_us    = dt_us;
            RES.x_mm     = x_mm;
            RES.valid    = valid;
            RES.idx      = idx;
            RES.nPicked  = sum(isfinite(t0_S1_us) | isfinite(t0_S2_us));
        end


        %% ======================= 1b. 纯能量法（兼容旧脚本） =======================
        function RES = pick_all_events_energy(wave, fs, CH, preTrigPoints, GEO, Ecfg)
            if nargin < 6 || isempty(Ecfg)
                Ecfg = struct('p',0.03,'smooth_us',5);
            end
            Ns   = size(wave,1);
            Nev  = size(wave,3);

            t0_S1_us = nan(Nev,1);
            t0_S2_us = nan(Nev,1);
            dt_us    = nan(Nev,1);
            x_mm     = nan(Nev,1);
            valid    = false(Nev,1);
            idx      = nan(Nev,2);

            win = max(1, round(Ecfg.smooth_us * 1e-6 * fs));

            for ev = 1:Nev
                s1 = double(wave(:, CH.S1, ev));
                s2 = double(wave(:, CH.S2, ev));

                [k1, t1_us] = AE_Tools_V3.pick_one_energy(s1, fs, preTrigPoints, Ecfg.p, win);
                [k2, t2_us] = AE_Tools_V3.pick_one_energy(s2, fs, preTrigPoints, Ecfg.p, win);

                idx(ev,:) = [k1, k2];

                if isfinite(k1) && isfinite(k2)
                    t0_S1_us(ev) = t1_us;
                    t0_S2_us(ev) = t2_us;
                    dt_us(ev)    = t2_us - t1_us;

                    if nargin >= 5 && ~isempty(GEO)
                        [x_mm(ev), valid(ev)] = AE_Tools_V3.geo_from_dt(dt_us(ev), GEO);
                    else
                        valid(ev) = true;
                    end
                end
            end

            RES = struct();
            RES.t0_S1_us = t0_S1_us;
            RES.t0_S2_us = t0_S2_us;
            RES.dt_us    = dt_us;
            RES.x_mm     = x_mm;
            RES.valid    = valid;
            RES.idx      = idx;
            RES.nPicked  = sum(valid);
        end


        %% ======================= 2. 单通道：能量比例起点 =======================
        function [k0_samp, t0_us] = pick_one_energy(x, fs, preTrigPoints, p, win)
            x = double(x(:));
            N = numel(x);

            if nargin < 3 || isempty(preTrigPoints)
                preTrigPoints = min(round(50e-6 * fs), N);
            end
            if nargin < 4 || isempty(p),   p   = 0.03; end
            if nargin < 5 || isempty(win), win = max(1, round(5e-6 * fs)); end

            e = x.^2;
            if win > 1
                e = conv(e, ones(win,1)/win, 'same');
            end

            if preTrigPoints >= N
                k0_samp = NaN; t0_us = NaN; return;
            end

            tot = sum(e(preTrigPoints+1:end));
            if tot <= 0
                k0_samp = NaN; t0_us = NaN; return;
            end

            c   = cumsum(e(preTrigPoints+1:end));
            idx = find(c >= p*tot, 1, 'first');
            if isempty(idx)
                k0_samp = NaN; t0_us = NaN; return;
            end

            k0_samp = preTrigPoints + idx;
            t0_us   = (k0_samp - 1)/fs * 1e6;
        end


        %% ======================= 3. 单通道：稳健 AIC 起点 =======================
        function [k0_samp, t0_us, k_thr] = pick_one_robust(x, fs, preTrigPoints, thr_factor)
            % 参考 Maeda (1985) AIC，先用阈值找粗起点，再在窗口内做 AIC，
            % 最终起点不晚于阈值交叉点（对高 SNR AE 更安全）。

            x  = double(x(:));
            N  = numel(x);
            dt = 1/fs;

            if nargin < 3 || isempty(preTrigPoints)
                preTrigPoints = min(round(50e-6 * fs), N);
            end
            if nargin < 4 || isempty(thr_factor)
                thr_factor = 8;
            end

            % ---- 1) 滤波 + 噪声估计 ----
            try
                [b,a]  = butter(3, [20e3, 800e3] / (fs/2), 'bandpass');
                x_filt = filtfilt(b, a, x);
            catch
                x_filt = x - mean(x);
            end

            i_noise = 1:preTrigPoints;
            if isempty(i_noise)
                i_noise = 1:min(200,N);
            end

            sigma0 = std(x_filt(i_noise));
            if sigma0 < 5e-4, sigma0 = 5e-4; end

            thr = thr_factor * sigma0;

            % ---- 2) 从 preTrig 之后找第一次超阈值 ----
            search_start = min(preTrigPoints + 1, N);
            idx_cross    = find(abs(x_filt(search_start:end)) >= thr, 1, 'first');

            if isempty(idx_cross)
                % ---- Fallback: no threshold crossing found ----
                % Keep the main robust logic unchanged for normal signals.
                % For weak / non-triggering signals, force a reasonable onset (TOA) so that
                % downstream analyses (e.g., clustering) can still use an onset reference.
                [k0_samp, t0_us] = AE_Tools_V3.pick_one_fallback_simple(x_filt, fs, preTrigPoints);
                k_thr = NaN;
                return;
            end

            k_thr = search_start - 1 + idx_cross;

            % ---- 3) 以 k_thr 为中心的 AIC 窗 ----
            pre_win  = round(60e-6 * fs);
            post_win = round(40e-6 * fs);

            i1 = max(1,   k_thr - pre_win);
            i2 = min(N,   k_thr + post_win);

            if i2 <= i1 + 5
                k0_samp = k_thr;
                t0_us   = (k0_samp - 1)*dt*1e6;
                return;
            end

            % ---- 4) 窗内 AIC ----
            k0_samp = AE_Tools_V3.run_maeda_aic(x_filt, i1, i2);

            if ~isfinite(k0_samp) || k0_samp < i1 || k0_samp > i2
                k0_samp = k_thr;
            end

            % 强制不晚于阈值交叉
            if k0_samp > k_thr
                k0_samp = k_thr;
            end

            t0_us = (k0_samp - 1)*dt*1e6;
        end


        
        %% ======================= 3b. Fallback 起点（仅在主拾取失败时使用） =======================
        function [k0_samp, t0_us] = pick_one_fallback_simple(x_filt, fs, preTrigPoints)
            % pick_one_fallback_simple
            % 目的：当 pick_one_robust 无法找到阈值交叉（弱信号/噪声型事件）时，
            %       仍然给出一个“相对合理”的起点，用于后续对齐、特征窗口、聚类等。
            %
            % Level-1 (preferred): Peak-backtrack AIC
            %   - 以全局 peak 为锚点，向前回看一段窗口，在窗口内做 Maeda-AIC，取最小点为起点
            %   - 不依赖阈值触发，因此对“完全不触发”的事件也能工作
            %
            % Level-2 (backup): Envelope persistent crossing
            %   - 计算包络（Hilbert），用预触发段估计噪声分布
            %   - 找到“连续 M 点超过阈值”的最早点，降低单点噪声尖峰误触发
            %
            % 最后兜底：若仍失败，则取 peak（保证永不 NaN）

            x_filt = double(x_filt(:));
            N  = numel(x_filt);
            dt = 1/fs;

            if nargin < 3 || isempty(preTrigPoints)
                preTrigPoints = min(round(50e-6 * fs), N);
            end
            preTrigPoints = max(1, min(preTrigPoints, N));

            % ---------- Level-1: Peak-backtrack AIC ----------
            [~, k_peak] = max(abs(x_filt));

            back_us = 300;   % 可调：200~500（越大越容易抓到弱前驱，但也更容易混入噪声/反射）
            post_us = 40;

            back_samp = round(back_us  * 1e-6 * fs);
            post_samp = round(post_us  * 1e-6 * fs);

            i1 = max(preTrigPoints + 1, k_peak - back_samp);
            i2 = min(N,               k_peak + post_samp);

            if (i2 - i1 + 1) >= 30
                k_try = AE_Tools_V3.run_maeda_aic(x_filt, i1, i2);
                if isfinite(k_try) && k_try >= i1 && k_try <= i2
                    k0_samp = k_try;
                    t0_us   = (k0_samp - 1) * dt * 1e6;
                    return;
                end
            end

            % ---------- Level-2: Envelope persistent crossing ----------
            i_noise = 1:preTrigPoints;
            if isempty(i_noise)
                i_noise = 1:min(200, N);
            end

            % Hilbert envelope (with safety fallback)
            try
                env = abs(hilbert(x_filt));
            catch
                % 若没有 hilbert（极少数环境），用平滑绝对值近似包络
                w = max(3, round(5e-6 * fs));  % 5 us smoothing
                env = movmean(abs(x_filt), w);
            end

            mu = median(env(i_noise));
            sd = 1.4826 * mad(env(i_noise), 1);   % robust sigma
            if ~isfinite(sd) || sd <= 0
                sd = std(env(i_noise));
            end
            if ~isfinite(sd) || sd <= 0
                sd = eps;
            end

            K   = 3.5;     % 相对温和的门限（相比 robust 的 8*sigma）
            M   = 8;       % 连续 M 点超过阈值才认可（抑制尖峰）
            thr = mu + K * sd;

            k0_samp = NaN;
            startIdx = min(preTrigPoints + 1, N);
            for i = startIdx : (N - M)
                if all(env(i:i+M-1) > thr)
                    k0_samp = i;
                    break;
                end
            end

            % ---------- Final fallback: peak ----------
            if ~isfinite(k0_samp)
                k0_samp = max(preTrigPoints + 1, k_peak);
            end

            t0_us = (k0_samp - 1) * dt * 1e6;
        end


%% ======================= 4. Deep Hunt：向前追 S0 =======================
        function k_deep = pick_one_deep_hunt(x, fs, k_thr_main, preTrigPoints)
            x = double(x(:));
            N = numel(x);

            try
                [b,a]  = butter(3,[20e3,800e3]/(fs/2),'bandpass');
                x_filt = filtfilt(b,a,x);
            catch
                x_filt = x - mean(x);
            end

            if nargin < 4 || isempty(preTrigPoints)
                preTrigPoints = min(round(50e-6 * fs), N);
            end

            i_noise = 1:preTrigPoints;
            if isempty(i_noise), i_noise = 1:min(200,N); end
            sigma0 = std(x_filt(i_noise));
            if sigma0 < 5e-4, sigma0 = 5e-4; end

            lookback = round(400e-6 * fs);
            i1 = max(1, k_thr_main - lookback);
            i2 = max(i1+20, k_thr_main - round(10e-6*fs));

            if i2 <= i1 + 5
                k_deep = k_thr_main;
                return;
            end

            k_deep = AE_Tools_V3.run_maeda_aic(x_filt, i1, i2);

            amp = abs(x_filt(k_deep));
            if amp < 1.2 * sigma0
                k_deep = k_thr_main;
            end
        end


        %% ======================= 5. Maeda AIC 核心 =======================
        function k_best = run_maeda_aic(x, i1, i2)
            % Maeda N. (1985) Bull. Seismol. Soc. Am. 75, 1223–1240

            x = double(x(:));
            N = numel(x);

            if nargin < 2 || isempty(i1), i1 = 1; end
            if nargin < 3 || isempty(i2), i2 = N; end

            i1 = max(1, i1);
            i2 = min(N, i2);

            if i2 <= i1 + 2
                k_best = i1;
                return;
            end

            seg = x(i1:i2);
            M   = numel(seg);
            g   = 2;
            k_c = (1+g):(M-g);
            if isempty(k_c)
                k_best = i1;
                return;
            end

            cs  = cumsum(seg);
            cs2 = cumsum(seg.^2);
            St  = cs(end);
            S2t = cs2(end);

            aic = zeros(size(k_c));

            for ii = 1:numel(k_c)
                k  = k_c(ii);
                n1 = k;
                n2 = M-k;

                mu1 = cs(k)/n1;
                v1  = (cs2(k)/n1) - mu1^2;
                if v1 <= 0, v1 = eps; end

                mu2 = (St - cs(k))/n2;
                v2  = ((S2t - cs2(k))/n2) - mu2^2;
                if v2 <= 0, v2 = eps; end

                aic(ii) = n1*log(v1) + n2*log(v2);
            end

            [~,ix] = min(aic);
            k_best = i1 + k_c(ix) - 1;
        end


        %% ======================= 6. 辅助函数 =======================
        function C = fill_defaults(C, fs)
            %#ok<INUSD>
            if nargin < 1 || isempty(C), C = struct(); end
            if ~isfield(C,'thr_main_factor'), C.thr_main_factor = 8;   end
            if ~isfield(C,'dt_rel_margin'),   C.dt_rel_margin   = 0.2; end
            if ~isfield(C,'deep_all'),        C.deep_all        = false; end
            if ~isfield(C,'RefineFcn'),       C.RefineFcn       = [];  end
        end

        function [x_mm, ok] = geo_from_dt(dt_us, GEO)
            L_mm = GEO.L_mm;
            v_ms = GEO.v_ms;
            x_mm = (L_mm - v_ms * dt_us * 1e-3) / 2;
            tol_mm = 10;
            ok = (x_mm >= -tol_mm) & (x_mm <= L_mm + tol_mm);
        end

        function kend = find_end_by_energy(xsum, fs, k0, p_end)
            xsum = double(xsum(:));
            N    = numel(xsum);
            csum = cumsum(xsum);

            if k0 < 1 || k0 > N, k0 = 1; end

            if k0 > 1
                b = csum(k0-1);
            else
                b = 0;
            end

            tot = csum(end) - b;
            if tot <= 0
                kend = min(k0 + round(400e-6*fs), N);
                return;
            end

            tar = b + p_end*tot;
            idx = find(csum >= tar, 1, 'first');
            if isempty(idx), idx = N; end
            kend = idx;
        end

    end
end
