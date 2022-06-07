classdef jrodas_jhincapie_sortiz_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        PLAYButton                      matlab.ui.control.Button
        LimpiarButton_3                 matlab.ui.control.Button
        HzLabel_2                       matlab.ui.control.Label
        FrecuenciainferiorEditFieldLabel_3  matlab.ui.control.Label
        FrecuenciainferiorEditField_2   matlab.ui.control.NumericEditField
        FrecuenciainferiorEditField_2Label  matlab.ui.control.Label
        FrecuenciasuperiorEditField_2   matlab.ui.control.NumericEditField
        FrecuenciasuperiorEditField_2Label  matlab.ui.control.Label
        textoaquiLabel                  matlab.ui.control.Label
        TopologiadefiltroDropDown       matlab.ui.control.DropDown
        TopologiadefiltroDropDownLabel  matlab.ui.control.Label
        FiltroDropDown                  matlab.ui.control.DropDown
        FiltroDropDownLabel             matlab.ui.control.Label
        CargaraudioButton               matlab.ui.control.Button
        UIAxes3                         matlab.ui.control.UIAxes
        UIAxes2                         matlab.ui.control.UIAxes
        UIAxes                          matlab.ui.control.UIAxes
    end

%Authors
%Jessica Rodas Acevedo
%Johan Sebastian Hincapie Chavarria
%Sebastian Ortiz Pérez

    properties (Access = private)
        audio
        fullpathname
        Fs
        wp
        ftype
        t
        monofono
        m
        wp1
        wp2
        wpf
        wpt
        ESDfil
        out
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: CargaraudioButton
        function CargaraudioButtonPushed(app, event)
            audioCargado = uigetfile('*.mp3','Seleccione un audio');
            [app.audio,app.Fs]=audioread( audioCargado);
            app.monofono = (app.audio(:,1)+app.audio(:,2))/2;
            app.t=linspace(0,size(app.monofono,1)/app.Fs,length(app.monofono));                  

            plot(app.UIAxes2,app.t,app.monofono,'g');                       
        end

        % Value changed function: FiltroDropDown
        function FiltroDropDownValueChanged(app, event)
            value=app.FiltroDropDown.Value;
            freccorte= app.FrecuenciasuperiorEditField_2.Value;
            frecsup=app.FrecuenciasuperiorEditField_2.Value;
            frecinf=app.FrecuenciainferiorEditField_2.Value;

            if value == 1       
                app.m=[0 0 1 1];
                app.ftype = 'high';
                app.wp1 = frecsup/(app.Fs/2);
                app.wpf= app.wp1;
                app.wpt= [0 app.wp1 app.wp1+0.01 1];
            elseif value == 2
                app.m=[1 1 0 0];
                app.ftype = 'low';
                app.wp1 = frecsup/(app.Fs/2);
                app.wpf=app.wp1;
                app.wpt= [0 app.wp1 app.wp1+0.01 1];
            elseif value == 3
                app.m=[1 1 0 0 1 1];
                app.ftype = 'stop';
                app.wp1 = frecinf/(app.Fs/2);
                app.wp2 = frecsup/(app.Fs/2);
                app.wpf = [app.wp1 app.wp2];
                app.wpt=[0 app.wp1-0.01 app.wp1 app.wp2 app.wp2+0.01 1];
            elseif value == 4
                app.m=[0 0 1 1 0 0];
                app.ftype = 'bandpass';
                app.wp1 = frecinf/(app.Fs/2);
                app.wp2 = frecsup/(app.Fs/2);
                app.wpf = [app.wp1 app.wp2];
                app.wpt=[0 app.wp1-0.01 app.wp1 app.wp2 app.wp2+0.01 1];
            end         
        end

        % Value changed function: TopologiadefiltroDropDown
        function TopologiadefiltroDropDownValueChanged(app, event)
            topologia = app.TopologiadefiltroDropDown.Value;
            O=100; %orden del filtro
            Rp=.5;
            Rs=60;
            o=2;
            if topologia == 1
                nume = fir1(O,app.wpf,app.ftype);
                deno = 1;                
            elseif topologia == 2
                nume = fir2(O,app.wpt,app.m);
                deno = 1;                
            elseif topologia ==3
                nume = firpm(O,app.wpt,app.m);        
                deno = 1;                  
            elseif topologia ==4
                [nume,deno] = butter(o,app.wpf,app.ftype);
            elseif topologia ==5
                [nume,deno] = cheby1(o,Rp,app.wpf,app.ftype);                              
            elseif topologia ==6
                [nume,deno] = cheby2(o,Rs,app.wpf,app.ftype);                             
            elseif topologia ==7
                [nume,deno] = ellip(o,Rp,Rs,app.wpf,app.ftype);       
            end
app.out = filter(nume,deno,app.monofono);  
plot(app.UIAxes2,app.t,app.out,'r')

[h,w]=freqz(nume,deno,length(app.monofono));
plot(app.UIAxes,w*app.Fs/(2*pi),20*log10(abs(h)));   
fftoriginal=fft(app.monofono);
fftfiltrada=fft(app.out);

ESDor=abs(fftoriginal).^2;
app.ESDfil=abs(fftfiltrada).^2;

freq=(linspace(0,app.Fs,length(fftoriginal)));

plot(app.UIAxes2,app.t,app.out)

plot(app.UIAxes3,freq(1:end/2),10*log10(ESDor(1:end/2)),'blue')                                                            
plot(app.UIAxes3,freq(1:end/2),10*log10(app.ESDfil(1:end/2)),'red')
        end

        % Button pushed function: LimpiarButton_3
        function LimpiarButton_3Pushed(app, event)
            delete(app.UIAxes)
            delete(app.UIAxes2)
            delete(app.UIAxes3)
            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Respuesta en frecuencia')
            xlabel(app.UIAxes, 'Frecuencia (Hz)')
            ylabel(app.UIAxes, 'H(\omega) (dB)')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.FontWeight = 'bold';
            app.UIAxes.ColorOrder = [0 0.4471 0.7412;0.851 0.3255 0.098;0.9294 0.6941 0.1255;0.4941 0.1843 0.5569;0.4667 0.6745 0.1882;0.302 0.7451 0.9333;0.6353 0.0784 0.1843];
            app.UIAxes.NextPlot = 'add';
            app.UIAxes.Position = [41 48 300 185];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.UIFigure);
            title(app.UIAxes2, 'Señal Original vs Señal Filtrada')
            xlabel(app.UIAxes2, 'Tiempo (s)')
            ylabel(app.UIAxes2, 'Amplitud')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.FontWeight = 'bold';
            app.UIAxes2.NextPlot = 'add';
            app.UIAxes2.Position = [405 48 300 185];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.UIFigure);
            title(app.UIAxes3, 'Densidad espectral de energia')
            xlabel(app.UIAxes3, 'Frecuencia (Hz)')
            ylabel(app.UIAxes3, 'dB/Hz')
            zlabel(app.UIAxes3, 'Z')
            app.UIAxes3.FontWeight = 'bold';
            app.UIAxes3.NextPlot = 'add';
            app.UIAxes3.Position = [739 48 300 185];
            
            plot(app.UIAxes2,app.t,app.monofono,'r');
        end

        % Button pushed function: PLAYButton
        function PLAYButtonPushed(app, event)
           sound (app.out,app.Fs)                                
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1073 471];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Respuesta en frecuencia')
            xlabel(app.UIAxes, 'Frecuencia (Hz)')
            ylabel(app.UIAxes, 'H(\omega) (dB)')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.FontWeight = 'bold';
            app.UIAxes.ColorOrder = [0 0.4471 0.7412;0.851 0.3255 0.098;0.9294 0.6941 0.1255;0.4941 0.1843 0.5569;0.4667 0.6745 0.1882;0.302 0.7451 0.9333;0.6353 0.0784 0.1843];
            app.UIAxes.NextPlot = 'add';
            app.UIAxes.Position = [41 48 300 185];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.UIFigure);
            title(app.UIAxes2, 'Señal Original vs Señal Filtrada')
            xlabel(app.UIAxes2, 'Tiempo (s)')
            ylabel(app.UIAxes2, 'Amplitud')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.FontWeight = 'bold';
            app.UIAxes2.NextPlot = 'add';
            app.UIAxes2.Position = [405 48 300 185];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.UIFigure);
            title(app.UIAxes3, 'Densidad espectral de energia')
            xlabel(app.UIAxes3, 'Frecuencia (Hz)')
            ylabel(app.UIAxes3, 'dB/Hz')
            zlabel(app.UIAxes3, 'Z')
            app.UIAxes3.FontWeight = 'bold';
            app.UIAxes3.NextPlot = 'add';
            app.UIAxes3.Position = [739 48 300 185];

            % Create CargaraudioButton
            app.CargaraudioButton = uibutton(app.UIFigure, 'push');
            app.CargaraudioButton.ButtonPushedFcn = createCallbackFcn(app, @CargaraudioButtonPushed, true);
            app.CargaraudioButton.Position = [49 398 100 23];
            app.CargaraudioButton.Text = 'Cargar audio';

            % Create FiltroDropDownLabel
            app.FiltroDropDownLabel = uilabel(app.UIFigure);
            app.FiltroDropDownLabel.HorizontalAlignment = 'right';
            app.FiltroDropDownLabel.Position = [481 389 32 22];
            app.FiltroDropDownLabel.Text = 'Filtro';

            % Create FiltroDropDown
            app.FiltroDropDown = uidropdown(app.UIFigure);
            app.FiltroDropDown.Items = {'Pasa Alta', 'Pasa Baja', 'Rechaza Banda', 'Pasa Banda'};
            app.FiltroDropDown.ItemsData = [1 2 3 4];
            app.FiltroDropDown.ValueChangedFcn = createCallbackFcn(app, @FiltroDropDownValueChanged, true);
            app.FiltroDropDown.Position = [528 389 146 22];
            app.FiltroDropDown.Value = 2;

            % Create TopologiadefiltroDropDownLabel
            app.TopologiadefiltroDropDownLabel = uilabel(app.UIFigure);
            app.TopologiadefiltroDropDownLabel.HorizontalAlignment = 'right';
            app.TopologiadefiltroDropDownLabel.Position = [714 390 100 22];
            app.TopologiadefiltroDropDownLabel.Text = 'Topologia de filtro';

            % Create TopologiadefiltroDropDown
            app.TopologiadefiltroDropDown = uidropdown(app.UIFigure);
            app.TopologiadefiltroDropDown.Items = {'Enventanado (FIR)', 'Muestreo en frecuencia (FIR)', 'Parks-McCleallan(FIR)', 'Butterworth(IIR)', 'Chebyshev I (IIR)', 'Chevyshev II (IIR)', 'Elíptico (IIR)'};
            app.TopologiadefiltroDropDown.ItemsData = [1 2 3 4 5 6 7];
            app.TopologiadefiltroDropDown.ValueChangedFcn = createCallbackFcn(app, @TopologiadefiltroDropDownValueChanged, true);
            app.TopologiadefiltroDropDown.Position = [829 389 191 23];
            app.TopologiadefiltroDropDown.Value = 3;

            % Create textoaquiLabel
            app.textoaquiLabel = uilabel(app.UIFigure);
            app.textoaquiLabel.FontWeight = 'bold';
            app.textoaquiLabel.Position = [74 257 521 100];
            app.textoaquiLabel.Text = {'PASOS:'; ''; '1. Cargue el audio'; '2. Ingrese las frecuencias inferior y superior, o bien frecuencia de corte en la superior. '; '3. Seleccione el filtro diferente al preseleccionado.'; '4. Seleccione la topología del filtro diferente al preseleccionado por defecto.'; ' '};

            % Create FrecuenciasuperiorEditField_2Label
            app.FrecuenciasuperiorEditField_2Label = uilabel(app.UIFigure);
            app.FrecuenciasuperiorEditField_2Label.HorizontalAlignment = 'right';
            app.FrecuenciasuperiorEditField_2Label.Position = [170 400 112 22];
            app.FrecuenciasuperiorEditField_2Label.Text = 'Frecuencia superior';

            % Create FrecuenciasuperiorEditField_2
            app.FrecuenciasuperiorEditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.FrecuenciasuperiorEditField_2.Position = [297 400 100 22];

            % Create FrecuenciainferiorEditField_2Label
            app.FrecuenciainferiorEditField_2Label = uilabel(app.UIFigure);
            app.FrecuenciainferiorEditField_2Label.HorizontalAlignment = 'right';
            app.FrecuenciainferiorEditField_2Label.Position = [170 368 105 22];
            app.FrecuenciainferiorEditField_2Label.Text = 'Frecuencia inferior';

            % Create FrecuenciainferiorEditField_2
            app.FrecuenciainferiorEditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.FrecuenciainferiorEditField_2.Position = [297 368 100 22];

            % Create FrecuenciainferiorEditFieldLabel_3
            app.FrecuenciainferiorEditFieldLabel_3 = uilabel(app.UIFigure);
            app.FrecuenciainferiorEditFieldLabel_3.HorizontalAlignment = 'right';
            app.FrecuenciainferiorEditFieldLabel_3.Position = [415 398 25 22];
            app.FrecuenciainferiorEditFieldLabel_3.Text = 'Hz';

            % Create HzLabel_2
            app.HzLabel_2 = uilabel(app.UIFigure);
            app.HzLabel_2.HorizontalAlignment = 'right';
            app.HzLabel_2.Position = [415 368 25 22];
            app.HzLabel_2.Text = 'Hz';

            % Create LimpiarButton_3
            app.LimpiarButton_3 = uibutton(app.UIFigure, 'push');
            app.LimpiarButton_3.ButtonPushedFcn = createCallbackFcn(app, @LimpiarButton_3Pushed, true);
            app.LimpiarButton_3.FontName = 'Arial';
            app.LimpiarButton_3.FontSize = 25;
            app.LimpiarButton_3.FontWeight = 'bold';
            app.LimpiarButton_3.FontColor = [0 0 1];
            app.LimpiarButton_3.Position = [724 288 106 38];
            app.LimpiarButton_3.Text = 'Limpiar';

            % Create PLAYButton
            app.PLAYButton = uibutton(app.UIFigure, 'push');
            app.PLAYButton.ButtonPushedFcn = createCallbackFcn(app, @PLAYButtonPushed, true);
            app.PLAYButton.FontSize = 25;
            app.PLAYButton.FontWeight = 'bold';
            app.PLAYButton.FontColor = [0 0 1];
            app.PLAYButton.Position = [875 288 100 38];
            app.PLAYButton.Text = 'PLAY';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = jrodas_jhincapie_sortiz_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end