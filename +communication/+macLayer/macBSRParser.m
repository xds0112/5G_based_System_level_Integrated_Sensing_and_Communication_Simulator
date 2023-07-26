function [lcgIdList, bufferSizeList] = macBSRParser(lcid, macBSR)
%macBSRParser Parses NR BSR MAC control element
%
%   [LCGIDLIST, BUFFERSIZELIST] = hNRMACBSRParser(LCID, MACBSR) parses the
%   received buffer status report (BSR) medium access control (MAC) control
%   element, as per 3GPP TS 38.321 Section 6.1.3.1 and returns the logical
%   channel group (LCG) ids and their buffer size.
%
%   LCID is the logical channel id (LCID) of the BSR control element.
%       - LCID = 59 represents short truncated BSR.
%       - LCID = 60 represents long truncated BSR.
%       - LCID = 61 represents short BSR.
%       - LCID = 62 represents long BSR.
%
%   MACBSR is a column vector of octets in decimal format.
%
%   LCGIDLIST is a column vector and contains LCG ids reported in the BSR.
%
%   BUFFERSIZELIST is a column vector and contains the current buffer size of
%   corresponding LCGs.

%   Copyright 2019 The MathWorks, Inc.

    % Validate inputs
    macBSR = validateInputs(lcid, macBSR);

    % If buffer is available but size is not reported in long truncated BSR
    % then reporting minimum amount of buffer size.
    bufferSizeIndex = 1;

    if  lcid == 59 || lcid == 61 % Short truncated BSR or short BSR
        %   Short BSR or short truncated BSR MAC control element contains
        %   following fields.
        %       LCGID            - Logical channel group id (3 bits).
        %       BufferSizeIndex  - Buffer size level index (5 bits) as per 
        %                          3GPP TS 38.321 Table 6.1.3.1-1.
        lcgIdList = bitshift(macBSR, -5);
        % Buffer size field length (in bits)
        bufferSizeFieldLength = 5;
        % Read the buffer size index
        bufferSizeIndex = bitand(macBSR, bitshift(255, -3));
        bufferSizeList = getBufferSize(bufferSizeIndex, bufferSizeFieldLength);
    elseif lcid == 60 || lcid == 62 % Long truncated BSR or long BSR
        %   Long BSR or long truncated BSR MAC control element contains
        %   following fields.
        %       LCGBITMAP        - Represents which LCG buffer status is
        %                          reported (8 bit).
        %       BufferSizeIndex  - Buffer size level index (8 bits) as per
        %                          3GPP TS 38.321 Table 6.1.3.1-2.

        % Buffer size field length (in bits)
        bufferSizeFieldLength = 8;
        lcgBitmap = bitget(macBSR(1), 1:8);
        numLCGs = numel(nonzeros(lcgBitmap));
        lcgIdList = zeros(numLCGs,1);
        bufferSizeList = zeros(numLCGs,1);
        payloadByteIndex = 1;
        numLCGReported = 0;
        for bitIndex = 1:8
            if lcgBitmap(bitIndex)
                numLCGReported = numLCGReported + 1;
                % Logical channel group id
                lcgIdList(numLCGReported) = bitIndex - 1;
                if payloadByteIndex < numel(macBSR)
                    % Data is available in buffers and buffer size is
                    % reported
                    payloadByteIndex = payloadByteIndex + 1;
                    bufferSizeList(numLCGReported) = getBufferSize(macBSR(payloadByteIndex), bufferSizeFieldLength);
                else
                    % Data is available in buffers but buffer size is not
                    % reported
                    bufferSizeList(numLCGReported) = getBufferSize(bufferSizeIndex, bufferSizeFieldLength);
                end
            end
        end
    end
end

function macBSR = validateInputs(lcid, macBSR)
% Validates the given input arguments

    % LCID is with in the valid range
    validateattributes(lcid,{'numeric'},{'nonempty','scalar','>=',59,'<=',62,'integer'},'lcid');

    % MAC BSR must be nonempty, vector of octets in decimal format
    validateattributes(macBSR, {'numeric'},{'nonempty','vector','>=',0,'<=',255,'integer'},'macBSR');

end

function bufferSize = getBufferSize(bufferSizeIndex, bufferSizeFieldLength)
% Performs buffersize calculation based on index

    if bufferSizeFieldLength == 5
        % bsTable contain 32 rows.
        bsTable = bufferSizeIndexTable();

        % Get the bufferSize for the matching bufferSizeIndex.
        % bufferSizeIndex is represented in 5 bits (0-31).
        bufferSize = bsTable(bufferSizeIndex + 1); % Indexing starts from 1
    else
        % bsTable contain 256 rows.
        bsTable = longBufferSizeIndexTable();

        % Get the bufferSize for the matching bufferSizeIndex.
        % bufferSizeIndex is represented in 5 bits (0-255).
        bufferSize = bsTable(bufferSizeIndex + 1); % Indexing starts from 1
    end
end

% 3GPP TS 38.321 Table 6.1.3.1-1
function bufferSize = bufferSizeIndexTable()
% Construct the static table

    persistent bufferSizeTable;
    if isempty(bufferSizeTable)
        bufferSizeTable = [0;10;14;20;28;38;53;74
            102;142;198;276;384;535;745;1038
            1446;2014;2806;3909;5446;7587;10570;
            14726;20516;28581;39818;55474;77284;
            107669;150000;150000];
    end
    bufferSize = bufferSizeTable;
end

% 3GPP TS 38.321 Table 6.1.3.1-2
function bsTable = longBufferSizeIndexTable()
% Construct the static table

    persistent longBufferSizeTable;
    if isempty(longBufferSizeTable)
        longBufferSizeTable = [0;10;11;12;13;14;15;16;17;18;19;20;22;23;25;26;28;30;32;34;36;38;
    40;43;46;49;52;55;59;62;66;71;75;80;85;91;97;103;110;117;124;
    132;141;150;160;170;181;193;205;218;233;248;264;281;299;318;339;
    361;384;409;436;464;494;526;560;597;635;677;720;767;817;870;926;987;
    1051;1119;1191;1269;1351;1439;1532;1631;1737;1850;1970;2098;2234;2379;
    2533;2698;2873;3059;3258;3469;3694;3934;4189;4461;4751;5059;5387;5737;
    6109;6506;6928;7378;7857;8367;8910;9488;10104;10760;11458;12202;12994;
    13838;14736;15692;16711;17795;18951;20181;21491;22885;24371;25953;
    27638;29431;31342;33376;35543;37850;40307;42923;45709;48676;51836;
    55200;58784;62599;66663;70990;75598;80505;85730;91295;97221;103532;
    110252;117409;125030;133146;141789;150992;160793;171231;182345;194182;
    206786;220209;234503;249725;265935;283197;301579;321155;342002;364202;
    387842;413018;439827;468377;498780;531156;565634;602350;641449;683087;
    727427;774645;824928;878475;935498;996222;1060888;1129752;1203085;
    1281179;1364342;1452903;1547213;1647644;1754595;1868488;1989774;
    2118933;2256475;2402946;2558924;2725027;2901912;3090279;3290873;
    3504487;3731968;3974215;4232186;4506902;4799451;5110989;5442750;
    5796046;6172275;6572925;6999582;7453933;7937777;8453028;9001725;
    9586039;10208280;10870913;11576557;12328006;13128233;13980403;
    14887889;15854280;16883401;17979324;19146385;20389201;21712690;
    23122088;24622972;26221280;27923336;29735875;31666069;33721553;
    35910462;38241455;40723756;43367187;46182206;49179951;52372284;
    55771835;59392055;63247269;67352729;71724679;76380419;81338368;81338368;inf];
    end
    bsTable = longBufferSizeTable;
end
