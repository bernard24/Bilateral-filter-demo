writerObj = VideoWriter('Bilateral_feature2.avi');
open(writerObj);

filter_size = 11;
gaussian_std = 20; %2;
bilateral_std = 0.1; %0.01;%0.1;
canvas_size = [400,600,3];

input_image_file = '/home/bernard/Dropbox/Photos/totana/mamen.png';
input_image_file = 'C:/Users/Bernard/Dropbox/Photos/totana/minielo.png';
features_file = 'C:/Users/Bernard/Dropbox/Photos/totana/minielo_heatmap.png';

input_image = imread(input_image_file);
features_image = imread(features_file);
[x_size, y_size, n_channels] = size(input_image);

top_left_input = [150, 20];
top_left_features = [150, 220];
top_left_output = [150+floor(filter_size/2), 420];
top_left_patch = [20, 20 + floor(x_size/2)];
top_left_features_patch = [80, 220 + floor(x_size/2)];
top_left_filter = [20, 520];
top_left_bilateral = [20, 420];
top_left_resultant = [80, 470];

filter_representation_zoom = 4;



gaussian_filter = fspecial('gaussian', filter_size, gaussian_std);
vec_gaussian_filter = gaussian_filter(1:end)';
gaussian_filter_representation = 255*(gaussian_filter-min(vec_gaussian_filter))/(max(vec_gaussian_filter)-min(vec_gaussian_filter));
gaussian_filter_representation = repmat(gaussian_filter_representation, [1,1,n_channels]);
gaussian_filter_representation = uint8(imresize(gaussian_filter_representation, filter_representation_zoom));
% figure
% imagesc(gaussian_filter);
canvas = uint8(Inf(canvas_size));

x_output_size = x_size - filter_size - 1;
y_output_size = y_size - filter_size - 1;
output = uint8(zeros(x_output_size, y_output_size, n_channels));

canvas(top_left_input(1):top_left_input(1)+x_size-1, top_left_input(2):top_left_input(2)+y_size-1, :) = input_image;
canvas(top_left_filter(1):top_left_filter(1)+filter_size*filter_representation_zoom-1, top_left_filter(2):top_left_filter(2)+filter_size*filter_representation_zoom-1, :) = gaussian_filter_representation;

% figure
% imshow(canvas)

frame = 1;
for i = 1:x_output_size
    disp([i,x_output_size])
    for j = 1:y_output_size
        canvas = uint8(Inf(canvas_size));
        canvas(top_left_input(1):top_left_input(1)+x_size-1, top_left_input(2):top_left_input(2)+y_size-1, :) = input_image;
        canvas(top_left_features(1):top_left_features(1)+x_size-1, top_left_features(2):top_left_features(2)+y_size-1, :) = features_image;
        canvas(top_left_filter(1):top_left_filter(1)+filter_size*filter_representation_zoom-1, top_left_filter(2):top_left_filter(2)+filter_size*filter_representation_zoom-1, :) = gaussian_filter_representation;
        
 
        input_copy = input_image;
        input_copy(i, j:j+filter_size-1,:) = 255;
        input_copy(i+filter_size-1, j:j+filter_size-1,:) = 255;
        input_copy(i:i+filter_size-1, j,:) = 255;
        input_copy(i:i+filter_size-1, j+filter_size-1,:) = 255;
        
        features_copy = features_image;
        features_copy(i, j:j+filter_size-1,:) = 255;
        features_copy(i+filter_size-1, j:j+filter_size-1,:) = 255;
        features_copy(i:i+filter_size-1, j,:) = 255;
        features_copy(i:i+filter_size-1, j+filter_size-1,:) = 255;
        
        roi = input_image(i:i+filter_size-1, j:j+filter_size-1,:);
        bilateral_aux = repmat(roi(floor(filter_size/2)+1,floor(filter_size/2)+1,:), filter_size, filter_size);
        bilateral_aux = sqrt(sum((double(bilateral_aux-roi)/255).^2, 3));
        bilateral_filter = normpdf(bilateral_aux,0,bilateral_std);
        
        bilateral_filter_representation = 255*(bilateral_filter-min(bilateral_filter(1:end)))/(max(bilateral_filter(1:end))-min(bilateral_filter(1:end)));
        bilateral_filter_representation = repmat(bilateral_filter_representation, [1,1,n_channels]);
        bilateral_filter_representation = uint8(imresize(bilateral_filter_representation, filter_representation_zoom));

        resultant_filter = bilateral_filter.*gaussian_filter;
        resultant_filter = resultant_filter/sum(resultant_filter(1:end));
        vec_resultant_filter = resultant_filter(1:end);

        resultant_filter_representation = 255*(resultant_filter-min(resultant_filter(1:end)))/(max(resultant_filter(1:end))-min(resultant_filter(1:end)));
        resultant_filter_representation = repmat(resultant_filter_representation, [1,1,n_channels]);
        resultant_filter_representation = uint8(imresize(resultant_filter_representation, filter_representation_zoom));
        
        
        roi_features = features_image(i:i+filter_size-1, j:j+filter_size-1,:);
        for k = 1:n_channels
            roi_slice = roi_features(:,:,k);
            output(i,j,k) = uint8(double(roi_slice(1:end))*vec_resultant_filter');
        end
        roi_representation = imresize(roi, filter_representation_zoom);
        roi_features_representation = imresize(roi_features, filter_representation_zoom);
        
        canvas(top_left_input(1):top_left_input(1)+x_size-1, top_left_input(2):top_left_input(2)+y_size-1, :) = input_copy;
        canvas(top_left_output(1):top_left_output(1)+x_output_size-1, top_left_output(2):top_left_output(2)+y_output_size-1, :) = output;
        canvas(top_left_features(1):top_left_features(1)+x_size-1, top_left_features(2):top_left_features(2)+y_size-1, :) = features_copy;

        coord_x = [j+top_left_input(2),  top_left_patch(2),  top_left_patch(2)-1, j+top_left_input(2)-1];
        coord_y = [i+top_left_input(1),  top_left_patch(1),  top_left_patch(1)-1, i+top_left_input(1)-1];
        mask = repmat(poly2mask(coord_x, coord_y, canvas_size(1), canvas_size(2)), [1,1,3]);
        coord_x = [j+top_left_input(2)+filter_size-1,  top_left_patch(2)+filter_size*filter_representation_zoom-1,  top_left_patch(2)+filter_size*filter_representation_zoom-2, j+top_left_input(2)+filter_size-2];
        coord_y = [i+top_left_input(1),  top_left_patch(1),  top_left_patch(1)-1, i+top_left_input(1)-1];
        mask = mask + repmat(poly2mask(coord_x, coord_y, canvas_size(1), canvas_size(2)), [1,1,3]);
        coord_x = [j+top_left_input(2),  top_left_patch(2),  top_left_patch(2)-1, j+top_left_input(2)-1];
        coord_y = [i+top_left_input(1)+filter_size-1,  top_left_patch(1)+filter_size*filter_representation_zoom-1,  top_left_patch(1)+filter_size*filter_representation_zoom-2, i+top_left_input(1)+filter_size-2];
        mask = mask + repmat(poly2mask(coord_x, coord_y, canvas_size(1), canvas_size(2)), [1,1,3]);
        coord_x = [j+top_left_input(2)+filter_size-1,  top_left_patch(2)+filter_size*filter_representation_zoom-1,  top_left_patch(2)+filter_size*filter_representation_zoom-2, j+top_left_input(2)+filter_size-2];
        coord_y = [i+top_left_input(1)+filter_size-1,  top_left_patch(1)+filter_size*filter_representation_zoom-1,  top_left_patch(1)+filter_size*filter_representation_zoom-2, i+top_left_input(1)+filter_size-2];
        mask = mask + repmat(poly2mask(coord_x, coord_y, canvas_size(1), canvas_size(2)), [1,1,3]);
        canvas(mask>0)=200;
        
        coord_x = [j+top_left_features(2),  top_left_features_patch(2),  top_left_features_patch(2)-1, j+top_left_features(2)-1];
        coord_y = [i+top_left_features(1),  top_left_features_patch(1),  top_left_features_patch(1)-1, i+top_left_features(1)-1];
        mask = repmat(poly2mask(coord_x, coord_y, canvas_size(1), canvas_size(2)), [1,1,3]);
        coord_x = [j+top_left_features(2)+filter_size-1,  top_left_features_patch(2)+filter_size*filter_representation_zoom-1,  top_left_features_patch(2)+filter_size*filter_representation_zoom-2, j+top_left_features(2)+filter_size-2];
        coord_y = [i+top_left_features(1),  top_left_features_patch(1),  top_left_features_patch(1)-1, i+top_left_features(1)-1];
        mask = mask + repmat(poly2mask(coord_x, coord_y, canvas_size(1), canvas_size(2)), [1,1,3]);
        coord_x = [j+top_left_features(2),  top_left_features_patch(2),  top_left_features_patch(2)-1, j+top_left_features(2)-1];
        coord_y = [i+top_left_features(1)+filter_size-1,  top_left_features_patch(1)+filter_size*filter_representation_zoom-1,  top_left_features_patch(1)+filter_size*filter_representation_zoom-2, i+top_left_input(1)+filter_size-2];
        mask = mask + repmat(poly2mask(coord_x, coord_y, canvas_size(1), canvas_size(2)), [1,1,3]);
        coord_x = [j+top_left_features(2)+filter_size-1,  top_left_features_patch(2)+filter_size*filter_representation_zoom-1,  top_left_features_patch(2)+filter_size*filter_representation_zoom-2, j+top_left_features(2)+filter_size-2];
        coord_y = [i+top_left_features(1)+filter_size-1,  top_left_features_patch(1)+filter_size*filter_representation_zoom-1,  top_left_features_patch(1)+filter_size*filter_representation_zoom-2, i+top_left_features(1)+filter_size-2];
        mask = mask + repmat(poly2mask(coord_x, coord_y, canvas_size(1), canvas_size(2)), [1,1,3]);
        canvas(mask>0)=200;

        canvas(top_left_patch(1):top_left_patch(1)+filter_size*filter_representation_zoom-1, top_left_patch(2):top_left_patch(2)+filter_size*filter_representation_zoom-1, :) = roi_representation;
        canvas(top_left_features_patch(1):top_left_features_patch(1)+filter_size*filter_representation_zoom-1, top_left_features_patch(2):top_left_features_patch(2)+filter_size*filter_representation_zoom-1, :) = roi_features_representation;
        canvas(top_left_bilateral(1):top_left_bilateral(1)+filter_size*filter_representation_zoom-1, top_left_bilateral(2):top_left_bilateral(2)+filter_size*filter_representation_zoom-1, :) = bilateral_filter_representation;
        canvas(top_left_resultant(1):top_left_resultant(1)+filter_size*filter_representation_zoom-1, top_left_resultant(2):top_left_resultant(2)+filter_size*filter_representation_zoom-1, :) = resultant_filter_representation;

        
        if  mod(i,5)==1 & mod(j,2)==0 %frame<=100 | floor(log2(frame))==log2(frame)
%             imshow(canvas)
% %             line([j+top_left_input(2),top_left_patch(2)],[i+top_left_input(1),top_left_patch(1)],'Color','r','LineWidth',2)
%             drawnow;
              writeVideo(writerObj, canvas);
        end
%         if i==12
%             close(writerObj);
%             return
%         end
        frame = frame+1;
    end
end
canvas(top_left_input(1):top_left_input(1)+x_size-1, top_left_input(2):top_left_input(2)+y_size-1, :) = input_image;
canvas(top_left_output(1):top_left_output(1)+x_output_size-1, top_left_output(2):top_left_output(2)+y_output_size-1, :) = output;
imshow(canvas)
close(writerObj);
