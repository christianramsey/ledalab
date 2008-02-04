function downsample
global leda2

Fs = round(leda2.data.samplingrate);
 factorL = divisors(Fs);
 FsL = Fs./ factorL;    %list of possible new sampling rates

if isempty( FsL)
    msgbox('Current sampling rate can not be further broken down')
    return;
end

for i = 1:length(FsL)
     FsL_txt{i} = sprintf('%d Hz   (Factor %d)', FsL(i), factorL(i)); %#ok<AGROW>
end

fig = figure('Units','normalized','Position',[.4 .3 .2 .4],'Menubar','None','Name','Downsampling','Numbertitle','Off','Resize','Off');
uicontrol('Units','normalized','Style','Text','Position',[.1 .92 .8 .04],'String',['Downsample from ',num2str(Fs),'Hz to:'],'HorizontalAlignment','left','BackgroundColor',get(gcf,'Color'));
list_fs = uicontrol('Units','normalized','Style','listbox','Position',[.1 .3 .8 .6],'String', FsL_txt);
downsTypeL = {'factor steps','factor mean'};
uicontrol('Units','normalized','Style','Text','Position',[.1 .18 .3 .06],'String','Type:','HorizontalAlignment','left','BackgroundColor',get(gcf,'Color'));
popm = uicontrol('Units','normalized','Style','popupmenu','Position',[.3 .18 .4 .06],'String',downsTypeL,'Value',2);
uicontrol('Style','pushbutton','Units','normalized','Position',[.65 .05 .25 .06],'String','OK','Callback','uiresume(gcbf)','FontUnits','normalized');

uiwait(fig);
if ~ishandle(fig)  %deleted to cancel
    return
end

if ~isempty(leda2.analyze.fit)
    cmd = questdlg('The current fit will be deleted!','Warning','Continue','Cancel','Continue');
    if isempty(cmd) || strcmp(cmd, 'Cancel')
        return
    end
end

sel_fac = get(list_fs,'Value');
fac =  factorL(sel_fac);

typeTxtL = {'step', 'mean'};
type = typeTxtL{get(popm,'Value')};

close(fig);

[td, scd] = downsamp(leda2.data.time.data, leda2.data.conductance.data, fac, type);
%downsampling (type factor mean) may result in an additional offset = time(1), which will not be substracted (tim = time - offset) in order not to affect event times
leda2.data.time.data = td(:)';
leda2.data.conductance.data = scd(:)';
%update data statistics
leda2.data.N = length(leda2.data.time.data);
leda2.data.samplingrate =  FsL(sel_fac);
leda2.data.conductance.error = sqrt(mean(diff(scd).^2)/2);
leda2.data.conductance.min = min(scd);
leda2.data.conductance.max = max(scd);

delete_fit(0);
leda2.gui.rangeview.range = 60;
plot_data;
file_changed(1);
add2log(1,['Data downsampled to ', FsL_txt{sel_fac},'.'],1,1,1);
clear global dwnsmpl



function [t, data] = downsamp(t, data, fac, type)

N = length(data); %#samples
if strcmp(type,'step')
    t = t(1:fac:end);
    data = data(1:fac:end);

elseif strcmp(type,'mean')
    t = t(1:end-mod(N, fac));
    t = mean(reshape(t, fac, []))';
    data = data(1:end-mod(N, fac)); %reduce samples to match a multiple of <factor>
    data = mean(reshape(data, fac, []))'; %Mean of <factor> succeeding samples
end
