function w=forzcr(index,frame_len)
    if index>=0&&index<frame_len
        w=1/(2*frame_len);
    else
        w=0;
    end
end