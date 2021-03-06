function varargout = ImageSegmentation(varargin)%%do not edit
% IMAGESEGMENTATION MATLAB code for ImageSegmentation.fig
%      IMAGESEGMENTATION, by itself, creates a new IMAGESEGMENTATION or raises the existing
%      singleton*.
%
%      H = IMAGESEGMENTATION returns the handle to a new IMAGESEGMENTATION or the handle to
%      the existing singleton*.
%
%      IMAGESEGMENTATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMAGESEGMENTATION.M with the given input arguments.
%
%      IMAGESEGMENTATION('Property','Value',...) creates a new IMAGESEGMENTATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ImageSegmentation_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ImageSegmentation_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ImageSegmentation

% Last Modified by GUIDE v2.5 16-Oct-2015 14:50:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ImageSegmentation_OpeningFcn, ...
                   'gui_OutputFcn',  @ImageSegmentation_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ImageSegmentation is made visible.
function ImageSegmentation_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ImageSegmentation (see VARARGIN)

% Choose default command line output for ImageSegmentation
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
str='Please load a file';
set(handles.edit3,'string',str);
set(handles.slice,'string','slice');

% --- Outputs from this function are returned to the command line.
%output in matlab command window, do need to edit
function varargout = ImageSegmentation_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function slice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --------------------------------------------------------------------
%read a nd2 file,get the operation file 'evalue'
function openfile_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to openfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
str='Opening...Please wait.';
set(handles.edit3,'string',str);
[filename, pathname] = uigetfile('*.nd2','select the .nd2 file');
data = bfopen([ pathname,filename]);
series = data{1, 1};

x_size = size(series{1,1},1);%series{1,1} first cell(picture)
y_size = size(series{1,1},2);
z_size = size(series,1);%series includes 128 cells(picture)
global volume;
volume = zeros(x_size,y_size,z_size);%build a container

for z = 1:z_size
    plane = series{z,1};
    volume(:,:,z) = plane;
end
volume = volume(:,:,1:4:end); % 1:green; 2:green-yellow; 3:nir; 4:sum% save_nii(make_nii(volume,[1 1 1], [0 0 0], 4),'B.nii.gz')
sz=size(volume);
set(handles.slice,'string', {1:1:sz(3)});%set the selection of popupmenu by number 1 to sz(3) 

global evalue;
evalue=max(volume,[],3);% get the maxvalue of each pixel from all slice

%%cut the maximum part of the image for the effect of histogram equalization
maxvalue=max(max(max(evalue)));
A=find(evalue>maxvalue/4);
evalue(A)=maxvalue/4;

evalue=medfilt2(evalue);%median filter, remove the white noise

evalue_uint8=uint8(floor(evalue/16));
evalue_hist=histeq(evalue_uint8,256);%histogram equalization the image 'evalue', make the image easier to read
evalue=im2double(evalue_hist);
axes(handles.axes);%the left axes
imshow(evalue,[]);


%%image enhancement by average the dataset
% sum_all=ones(sz(3),1)/sz(3);
% 
% evalue=reshape(reshape(volume,[],sz(3))*sum_all,[sz(1:2) 1]);%ȡ��ֵ��ͼ���ǿ��
% evalue1=floor(evalue/16);%�ı�ȡֵ��Χ����Ӧֱ��ͼ���
% evalue2=uint8(evalue1);
% evalue3=histeq(evalue2,256);
% evalue=im2double(evalue3);
% axes(handles.axes);
% imshow(evalue,[]);



str='Finshed.';
set(handles.edit3,'string',str);

%%initialize some global value
global segOutline; % A 2-D 0-1 matrix stand for the result of segmentation, the edge consist of pixels which value are 1
segOutline=zeros(sz(1),sz(2));
segOutline=im2double(segOutline);

global cflag;%true already cut
cflag=0;

global sflag;%true already segment
sflag=0;

global rect;%the array about the coordinate of vertex of cutting rectangle  [y1,y2,x1,x2]
rect=[1,sz(2),1,sz(1)];%be careful about the order

global savevalue;%container saves evalue, used in function of restart
savevalue=[];




% --- Executes on selection change in popupmenu2.
function slice_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global volume;
global segOutline;
global cflag;
global sflag;
global rect;
slct=get(handles.slice,'value');
slice=volume(:,:,slct);%get a slice for volume dataset
if cflag==1%means image have been cut
slicecut=slice(rect(1):rect(2),rect(3):rect(4));
slice=slicecut;
end
axes(handles.axes5);
k=max(max(slice));
if sflag==1
slice=slice+segOutline*k;
end
imshow(slice,[0,k]);



% --- Executes on button press in selectpoint.
function selectpoint_Callback(hObject, eventdata, handles)
% hObject    handle to selectpoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
str='Choose points in the round';
set(handles.edit3,'string',str);
global evalue;
[X,Y]=size(evalue);

i=0;
n=4;%you can change the num of seeds
seed=[];
label=[0];
N=ones(1,n-1);
label=[label N];%first version, fixed 4 seeds and 2 types of labels.

str='Choose points on the round';
set(handles.edit3,'string',str);
axes(handles.axes);
while(i<n)   
    [x_p,y_p]=ginput(1);
    x_p=floor(x_p);
    y_p=floor(y_p);
    hold on
    plot(x_p,y_p,'g.','MarkerSize',5);
    seed=[seed,sub2ind([X Y],y_p,x_p)];
    i=i+1;
%     pause(1);   
end
hold off

global volume;
slct=get(handles.slice,'value');
slice=volume(:,:,slct);
global cflag;
global rect;
if cflag==1
slicecut=slice(rect(1):rect(2),rect(3):rect(4));
slice=slicecut;
end

[mask,probabilities] = random_walker(evalue,seed,label);
mask=reshape(mask,X,Y);

%%inflation
D=[0 1 0,1 1 1,0 1 0];
mask=imerode(mask,D);
mask=imclose(mask,D);

[fx,fy]=gradient(mask);
x_mask=find(fx);
y_mask=find(fy);
global segOutline;
segOutline=zeros(X,Y);
segOutline(x_mask)=1;
segOutline(y_mask)=1;
axes(handles.axes);
outcome1=evalue+segOutline*max(max(evalue));
imshow(outcome1,[]);
axes(handles.axes5);
outcome2=slice+segOutline*max(max(slice));
imshow(outcome2,[]);

global sflag;
sflag=1;

% --- Executes on button press in average.
function average_Callback(hObject, eventdata, handles)
% hObject    handle to average (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global segOutline;
global volume;
global cflag;
global rect;
slct=get(handles.slice,'value');
slice=volume(:,:,slct);
if cflag==1
slicecut=slice(rect(1):rect(2),rect(3):rect(4));
slice=slicecut;
end
num=sum(segOutline);
value=sum(segOutline.*slice)/num;
set(handles.text6,'string', num2str(value));


% --- Executes on button press in back.
function back_Callback(hObject, eventdata, handles)
% hObject    handle to back (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global volume;
% global pflag;
global segOutline;
global rect
global cflag
global sflag;
slct=get(handles.slice,'value');
if slct>1
 slct=slct-1;
end
set(handles.slice,'value',slct);

slice=volume(:,:,slct);
if cflag==1
slicecut=slice(rect(1):rect(2),rect(3):rect(4));
slice=slicecut;
end
axes(handles.axes5);
k=max(max(slice));
if sflag==1
slice=slice+segOutline*k;
end
imshow(slice,[0,k]);   




% --- Executes on button press in next.
function next_Callback(hObject, eventdata, handles)
% hObject    handle to next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global volume;
global segOutline;
global rect;
global cflag;
global sflag;
slct=get(handles.slice,'value');
sz=size(volume);
if slct<sz(3)
slct=slct+1;
end
set(handles.slice,'value',slct);
slice=volume(:,:,slct);
if cflag==1
slicecut=slice(rect(1):rect(2),rect(3):rect(4));
slice=slicecut;
end
axes(handles.axes5);
k=max(max(slice));
if sflag==1
slice=slice+segOutline*k;
end
imshow(slice,[0,k]);   


% --- Executes on button press in cut.
function cut_Callback(hObject, eventdata, handles)
% hObject    handle to cut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%---select and cut--
global volume
global evalue;
global rect;
str='Choose a rectangle with two point';
set(handles.edit3,'string',str);
axes(handles.axes);
[rx_1,ry_1]=ginput(1);
rx_1=floor(rx_1);ry_1=floor(ry_1);
hold on
plot(rx_1,ry_1,'r.','MarkerSize',5);
[rx_2,ry_2]=ginput(1);
rx_2=floor(rx_2);ry_2=floor(ry_2);
plot(rx_2,ry_2,'r.','MarkerSize',5);
hold off
rect=[ry_1,ry_2,rx_1,rx_2];
global savevalue;
savevalue={savevalue;evalue};
evaluecut=evalue(rect(1):rect(2),rect(3):rect(4));
evalue=evaluecut;
imshow(evalue,[]);
slct=get(handles.slice,'value');
slice=volume(:,:,slct);
slicecut=slice(rect(1):rect(2),rect(3):rect(4));
slice=slicecut;
axes(handles.axes5);
imshow(slice,[]);


global cflag;%ture:cflag=1,operate on cut iamge
cflag=1;



% --- Executes on button press in restart.
function restart_Callback(hObject, eventdata, handles)
% hObject    handle to restart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global volume;
global evalue;
global savevalue;
evalue=savevalue{2};%forms some kind of stack
axes(handles.axes);
imshow(evalue,[]);
slct=get(handles.slice,'value');
slice=volume(:,:,slct);
axes(handles.axes5);
imshow(slice,[]);

sz=size(volume);
global segOutline;
segOutline=zeros(sz(1),sz(2));
segOutline=im2double(segOutline);

global cflag;
cflag=0;

global rect;
rect=[1,sz(2),1,sz(1)];

global sflag;
sflag=0;

savevalue=savevalue{1};
