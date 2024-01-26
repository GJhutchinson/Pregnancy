function [baddata] = sliceviewer_dwi(dat,Ns,Nv,AX)
%SLIDEVIEWER this function allows the user to shuffle through
% the volumes providing the ability to discard the
% unwanted datasets.
% written by Lefas summer 2011


%-------------------------------------------------------------------------
% Definition of gui window properties
scrsz = get(0,'ScreenSize');
f = figure('Name',['Slice Preview Window'],...
    'NumberTitle','off','Visible','off','Resize','off',...
    'Position',[(scrsz(3)/2)-350 (scrsz(4)/2)-340 700 680]);

%-------------------------------------------------------------------------
% Definitions of properties of elements
Sstep = 1/(Ns-1);               % Defines the step of the slider used for 
                                % navigation through the slides

dstep = 1/(Nv-1);               % Defines the step of the slider used for 
                                % navigation through the volumes
baddata = zeros(Ns,Nv);

%-------------------------------------------------------------------------
% Inside gui elements
   % Definition of sliders for navigation through the slides and volumes,
   % panels containing the gui elements, and text-boxes containing 
   % necessary information about the current slides and dynamics
   
   control = uipanel('Parent',f,'Title',' Image Control ','FontSize',12,...
        'TitlePosition','centertop','Position',[0.009 0.002 0.98 0.10]);
  
   slid = uicontrol('Parent',control,'Style','slider','Min',1,'Max',Ns,...
          'Value',1,'SliderStep',[Sstep Sstep],'Position',...
          [470 11 200 20],'Callback',@display_Sslider_value);

   dslide = uicontrol('Parent',control,'Style','slider','Min',1,'Max',Nv,...
          'Value',1,'SliderStep',[dstep dstep],'Position',...
          [10 10 200 20],'Callback',@display_Dslider_value,'Tag','dslider');
   
   slide = uicontrol('Style','text','tag','stitle','String','Slice',...
           'Position',[550 39 30 12],'Parent',control);
   stext = uicontrol('Style','text','tag','stext','String',1,...
           'Position',[580 39 30 12],'Parent',control);
     
   volume = uicontrol('Style','text','tag','stitle','String','Volume',...
           'Position',[75 30 60 20],'Parent',control);
   dtext = uicontrol('Style','text','tag','dtext','String',1,...
           'Position',[135 30 20 20],'Parent',control);    
   
   flbutton = uicontrol('Parent',control,'Style','togglebutton',...
            'String','Flag','Value',0,'Position',[315 10 55 25],...
            'Callback',@flagbutton,'Tag','flagbutton');
   
   ftext = uicontrol('Style','text','String','Discard image',...
           'Position',[250 382 200 24],'HorizontalAlignment','center',...
           'FontWeight','bold','FontSize',16,'Visible','off',...
           'ForegroundColor','r','Tag','flagtext','BackgroundColor','k'); 
   
   pxinfo = uicontrol('Style','text','tag','pxinfo',...
                      'String','Pixel Info: ',...
                      'Position',[10 61 70 15],'Parent',f,...
                      'FontWeight','light','FontSize',10,...
                      'BackgroundColor',[0.8,0.8,0.8]);     
   
%-------------------------------------------------------------------------
% In this section all slices for the first volume are plotted

   for j = 1:Nv
       for i = 1:Ns
           rot_dat(:,:,i,j) = rot90(dat(:,:,i,j));
       end
   end
   
   dvalue = 1; svalue = 1; % The initial arguments

   % Plots the grayscale image with specified dimensions 

       s1 = subplot(1,1,1);
       set(s1,'Position',[0.12 0.15 0.775 0.815])
       ill = imagesc(rot_dat(:,:,svalue,dvalue),[AX]);axis off;colormap gray
   
          hold on
        M = size(rot_dat,1);
        N = size(rot_dat,2);
        for k = 10:10:M
            x = [1 N];
            y = [k k];
            plot(x,y,'Color','w','LineStyle','-');
        end
        for k = 10:10:N
            x = [k k];
            y = [1 M];
            plot(x,y,'Color','w','LineStyle','-');
        end
         hold off 
        
%    title(['For b-value ',num2str(Bhead(dvalue))],'FontSize',10,'Parent',s1);
%    colormap('gray')      
             
   
                                        
   hText = impixelinfoval(gcf,ill); % provides intensity points of the image
   
   set(hText,'FontWeight','light','FontSize',10,'Position',[81 61 200 15],'Parent',f,'BackgroundColor',[0.8,0.8,0.8])
%-------------------------------------------------------------------------     
set(f,'Visible','on')                      % Enables the gui DO NOT modify

                                           %Don't tell me what to do I need
                                           %to fix those stupid sliders
                                           %that don't round so it tries to
                                           %access slice 2.5 


    function display_Sslider_value(hObject,~)

        svalue = round(get((hObject),'Value'));
        hstext= findobj('Tag','stext');
        set(hstext,'String',num2str(svalue))

        ill = imagesc(rot_dat(:,:,svalue,dvalue),'Parent',s1); axis off;caxis([AX])
%         title(['Slice ',num2str(svalue),' for b-value ',num2str(Bhead(dvalue))],'FontSize',10,'Parent',s1)
            
        hold on
        M = size(rot_dat,1);
        N = size(rot_dat,2);
        for k = 10:10:M
            x = [1 N];
            y = [k k];
            plot(x,y,'Color','w','LineStyle','-');
        end
        for k = 10:10:N
            x = [k k];
            y = [1 M];
            plot(x,y,'Color','w','LineStyle','-');
        end
         hold off   
        
        hText = impixelinfoval(gcf,ill);
        set(hText,'FontWeight','light','FontSize',10,'Position',[81 61 200 15],'Parent',f,'BackgroundColor',[0.8,0.8,0.8])
        
        butstate = findobj('Tag','flagbutton');
        set(butstate,'Value',baddata(svalue,dvalue))
        
        if baddata(svalue,dvalue)==1
            fltext= findobj('Tag','flagtext');
            set(fltext,'Visible','on')
        else
            fltext= findobj('Tag','flagtext');
            set(fltext,'Visible','off')
        end
       
    end

    function display_Dslider_value(hObject,~)

        dvalue = get((hObject),'Value');
        hdtext= findobj('Tag','dtext');
        set(hdtext,'String',num2str(dvalue))
      
            s1 = subplot(1,1,1);
            set(s1,'Position',[0.12 0.15 0.775 0.815])
           
        ill = imagesc(rot_dat(:,:,svalue,dvalue),'Parent',s1); axis off; caxis([AX])
        colormap gray
%         title(['Slice ',num2str(svalue),' for b-value ',num2str(Bhead(dvalue))],'FontSize',10,'Parent',s1)
            
          hold on
        M = size(rot_dat,1);
        N = size(rot_dat,2);
        for k = 10:10:M
            x = [1 N];
            y = [k k];
            plot(x,y,'Color','w','LineStyle','-');
        end
        for k = 10:10:N
            x = [k k];
            y = [1 M];
            plot(x,y,'Color','w','LineStyle','-');
        end
         hold off 
        
        hText = impixelinfoval(gcf,ill);
        set(hText,'FontWeight','light','FontSize',10,'Position',[81 61 200 15],'Parent',f,'BackgroundColor',[0.8,0.8,0.8])
        
        butstate = findobj('Tag','flagbutton');
        set(butstate,'Value',baddata(svalue,dvalue))
        
        if baddata(svalue,dvalue)==1
            fltext= findobj('Tag','flagtext');
            set(fltext,'Visible','on')
        else
            fltext= findobj('Tag','flagtext');
            set(fltext,'Visible','off')
        end
       
    end

    function flagbutton(hObject,~)
        
        bstate = get((hObject),'Value');
        baddata(svalue,dvalue)=bstate;
               
         if bstate==1
            fltext= findobj('Tag','flagtext');
            set(fltext,'Visible','on')
         else
            fltext= findobj('Tag','flagtext');
            set(fltext,'Visible','off')
        end
       
    end

uiwait(f)

end

