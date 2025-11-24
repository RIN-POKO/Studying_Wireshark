-- プロトコルの定義
local omikuji_proto = Proto("omikuji", "おみくじプロトコル")

-- フィールドの定義 (ProtoFieldを使用)
-- 1. メッセージタイプ (1バイト)
local f_type = ProtoField.uint8("omikuji.type", "message type", base.DEC, 
    {[0] = "DEMAND (要求)", [1] = "RESPONSE (応答)"})

-- 2. コネクションID (8バイト, 64ビット整数に変更)
local f_conn_id = ProtoField.uint64("omikuji.conn_id", "connection id", base.HEX)

-- 3. 結果 (3バイトの値を読み込むため、uint32を定義)
local f_result = ProtoField.uint32("omikuji.result", "result", base.DEC, 
    {[0] = "大吉", [1] = "中吉", [2] = "小吉", [3] = "凶"})

-- プロトコルにフィールドを登録
omikuji_proto.fields = {f_type, f_conn_id, f_result}

-- ディセクタ関数
function omikuji_proto.dissector(buffer, pinfo, tree)
    local len = buffer:len()
    
    -- 要求パケットの最小長チェック (TYPE:1バイト + CONN_ID:8バイト = 9バイト)
    local MIN_REQUEST_LEN = 9
    if len < MIN_REQUEST_LEN then 
        pinfo.cols.protocol = "OMIKUJI"
        pinfo.cols['info'] = "Omikuji (Incomplete/Short Packet)"
        return 0
    end
    
    pinfo.cols.protocol = "OMIKUJI"
    
    local subtree = tree:add(omikuji_proto, buffer(), "おみくじプロトコル")
    
    -- 1バイト目を読み込んでパケットタイプを取得
    local pkt_type = buffer(0,1):uint()
    
    -- 共通フィールドの表示
    subtree:add(f_type, buffer(0,1))   -- オフセット 0, 長さ 1
    subtree:add(f_conn_id, buffer(1,8)) -- オフセット 1, 長さ 8

    
    pinfo.cols['info'] = "おみくじ " .. (pkt_type == 1 and "RESPONSE" or "DEMAND")
    -- if文で書く場合は以下
    -- local info_string
    -- if pkt_type == 1 then
    --     info_string = "RESPONSE"
    -- else
    --     info_string = "DEMAND"
    -- end
    -- pinfo.cols['info'] = "おみくじ " .. info_string
    
    -- 応答フィールドのみ結果フィールドを追加
    if pkt_type == 1 then
        -- 応答パケットの最小長チェック (TYPE:1 + CONN_ID:8 + RESULT:3 = 12バイト)
        local MIN_RESPONSE_LEN = 12
        if len >= MIN_RESPONSE_LEN then
            -- f_result (オフセット 9, 長さ 3)
            subtree:add(f_result, buffer(9,3))
        else
            -- 応答だが不完全な場合
            pinfo.cols['info'] = "おみくじ RESPONSE (Short Packet)"
        end
    end
end


-- UDPポート12345に対してのみディセクタを登録
local udp_table = DissectorTable.get("udp.port")
udp_table:add(12345, omikuji_proto)