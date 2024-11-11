clc;clear;close all;

% For test : only change the directory and accept change folder after run . 
directory = ".\Puzzle_1_160";

cd(directory);
I_orig = imread(".\Original.tif");
I_input = imread(".\Output.tif");

My_Soloution(I_input, I_orig, directory);

function final_img = My_Soloution(I, I_orig, directory)

    [rows cols depth] = size(I);
    str = split(directory , '_');
    patches_number = str2num(str(3));

    patch_size = sqrt(rows*cols / patches_number);

    patches = [];
    for i=1:patches_number-4
        patches = [patches , i];
    end

     num_levels = ceil(min(rows , cols) / (2 * patch_size));

     % disp(num_levels);
     
     for lvl=0:num_levels-1
        [I , patches] = Fill_Outer_Layer(I, patches , patch_size , lvl+1 , lvl+1 , 1 , lvl+1 , cols/patch_size-lvl , 1 , false , false);
        [I , patches] = Fill_Outer_Layer(I, patches , patch_size , lvl+1, rows/patch_size-lvl , 1 ,  cols/patch_size-lvl , cols/patch_size-lvl, 1 , false , false);
        [I , patches] = Fill_Outer_Layer(I, patches , patch_size , rows/patch_size-lvl , rows/patch_size-lvl , 1 , lvl+1 , cols/patch_size-lvl, 1 , false , false);
        [I , patches] = Fill_Outer_Layer(I, patches , patch_size , lvl+1, rows/patch_size-lvl, 1 , lvl+1 , lvl+1, 1 , false , false);
        % figure, imshow(I);
     end
    
    [I , patches] = Fill_Outer_Layer(I, patches , patch_size , 1 , rows/patch_size , 1 , 1 , cols/patch_size , 1 , false , true);

    
    final_img = I;
    % final_img = Fill_Outer_Layer(I , patches , patch_size);
    figure;imshow(I);

    my_psnr = psnr(final_img , I_orig);
    disp(['final_psnr : ' ,  num2str(my_psnr)]);
end

function [final_img , patches] = Fill_Outer_Layer(I , patches , patch_size , row_start , row_end , row_step , col_start , col_end , col_step , opposite_way , last_step)

    [rows cols depth] = size(I);

    writerObj=VideoWriter('Video_test.avi'); % Change the video file name
    for i=row_start:row_step:row_end
        for j=col_start:col_step:col_end
            scores = [];
            for z=1:size(patches , 2)
                n = patches(z);
                similarities = [];
                sides = cell(4, 1);
                part_filename = sprintf('.\\Patch_%d.tif', n);
                puzzle_part = imread(part_filename);
    
                if Has_Already_Placed(I((i-1)*patch_size+1:i*patch_size,(j-1)*patch_size+1:j*patch_size,:))
                    break;
                end
                if j ~= cols/patch_size
                    sides{1} = I((i-1)*patch_size+1:i*patch_size,j*patch_size+1:(j+1)*patch_size,:);
                end
                if j~=1
                    sides{2} = I((i-1)*patch_size+1:i*patch_size,(j-2)*patch_size+1:(j-1)*patch_size,:);
                end
                if i~=rows/patch_size
                    sides{3} = I(i*patch_size+1:(i+1)*patch_size,(j-1)*patch_size+1:j*patch_size,:);
                end
                if i~=1
                    sides{4} = I((i-2)*patch_size+1:(i-1)*patch_size,(j-1)*patch_size+1:j*patch_size,:);
                end
                
                if j~=8 & Has_Already_Placed(sides{1})
                    similarity = calculate_similarity(puzzle_part , sides{1} , 'right' , last_step);
                    similarities = [similarities , similarity];
                end
                if j~=1 & Has_Already_Placed(sides{2})
                    similarity = calculate_similarity(puzzle_part , sides{2} , 'left' , last_step);
                    similarities = [similarities , similarity];
                end
                if i~=5 & Has_Already_Placed(sides{3})
                    similarity = calculate_similarity(puzzle_part , sides{3} , 'bottom' , last_step);
                    similarities = [similarities , similarity];
                end
                if i~=1 & Has_Already_Placed(sides{4})
                    similarity = calculate_similarity(puzzle_part , sides{4} , 'top' , last_step);
                    similarities = [similarities , similarity];
                end
    
                score = mean(similarities);
                scores = [scores , score];
            end

            if length(scores)==0
                continue;
            end

            [max_score , max_score_index] = max(scores);

            if size(similarities , 2) == 0
                break;
            end

            if max_score < 20 & opposite_way == false & last_step == false
                [I , patches] = Fill_Outer_Layer(I, patches , patch_size , row_end , i , row_step*-1 , col_end , j , col_step*-1 , true , false);
                break;
            elseif max_score < 20 & opposite_way == true  & last_step == false
                    break
            end

            part_filename = sprintf('.\\Patch_%d.tif', patches(max_score_index));            
            disp(part_filename);
            puzzle_part = imread(part_filename);
           
            I((i-1)*patch_size+1:i*patch_size,(j-1)*patch_size+1:j*patch_size,:) = puzzle_part;
            imshow(I , []);
            patches([max_score_index]) = [];
        end
    end

    final_img = I;

end

function has_placed = Has_Already_Placed(I_part)
    if sum(sum(sum(I_part))) ~= 0
        has_placed = true;
    else
        has_placed = false;
    end
end

function score = calculate_similarity(part1, part2, direction , last_step)
        switch direction
            case 'right'
                edge1 = part1(:, end, :);
                edge2 = part2(:, 1, :);
            case 'left'
                edge1 = part1(:, 1, :);
                edge2 = part2(:, end, :);
            case 'bottom'
                edge1 = part1(end, :, :);
                edge2 = part2(1, :, :);
            case 'top'
                edge1 = part1(1, :, :);
                edge2 = part2(end, :, :);
            otherwise
                error('Invalid direction');
        end
        score = psnr(edge1 , edge2);
end