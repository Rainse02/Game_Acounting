import streamlit as st
import pandas as pd
import plotly.express as px
import os
import datetime

# --- 现代简约莫兰迪/扁平风色板 ---
MODERN_COLORS = ['#457B9D', '#A8DADC', '#E63946', '#2A9D8F', '#F4A261', '#E9C46A', '#264653']
DATA_FILE = "./data/game_expenses.csv"

def load_data():
    if os.path.exists(DATA_FILE):
        df = pd.read_csv(DATA_FILE)
        if "用户" not in df.columns:
            df.insert(0, "用户", "👤 默认用户")
    else:
        df = pd.DataFrame(columns=["用户", "日期", "厂商", "游戏", "项目", "单价", "数量", "总额", "备注"])
    
    # 强制转换日期格式，并处理空值（填充为“未指定”）
    df["日期"] = pd.to_datetime(df["日期"], errors="coerce").dt.date
    df["项目"] = df["项目"].fillna("未指定")
    df["游戏"] = df["游戏"].fillna("未指定")
    df["厂商"] = df["厂商"].fillna("未指定")
    return df

def save_data(df):
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
    df.to_csv(DATA_FILE, index=False)

# 初始化会话状态
if 'last_user' not in st.session_state: st.session_state.last_user = None
if 'last_pub' not in st.session_state: st.session_state.last_pub = None
if 'last_game' not in st.session_state: st.session_state.last_game = None
if 'last_item' not in st.session_state: st.session_state.last_item = None

df = load_data()

st.set_page_config(page_title="个人游戏账本", layout="wide")
st.title("🎮 个人游戏消费数据看板")

# 2. 侧边栏：全局控制与数据录入
with st.sidebar:
    st.header("⚙️ 用户切换")
    
    existing_users = df["用户"].dropna().unique().tolist() if not df.empty else ["👤 默认用户"]
    # 优化点：新增选项置顶
    user_options = ["➕ 新增用户..."] + existing_users
    user_idx = user_options.index(st.session_state.last_user) if st.session_state.last_user in user_options else 1
    
    u_col1, u_col2 = st.columns(2)
    with u_col1:
        selected_user = st.selectbox("当前操作用户", user_options, index=user_idx)
    with u_col2:
        if selected_user == "➕ 新增用户...":
            current_user = st.text_input("新昵称", placeholder="如: 👾 Player1", label_visibility="hidden", key="custom_user")
            if not current_user: current_user = "未命名用户"
        else:
            current_user = selected_user

    st.divider()
    st.header("📝 记一笔")
    st.caption("💡 提示：新增项已置顶，默认项目为“未指定”。")
    
    # 厂商选择：置顶新增和未指定
    p_col1, p_col2 = st.columns(2)
    with p_col1:
        existing_publishers = [p for p in df["厂商"].unique().tolist() if p != "未指定"]
        pub_options = ["➕ 新增厂商...", "未指定"] + existing_publishers
        pub_idx = pub_options.index(st.session_state.last_pub) if st.session_state.last_pub in pub_options else 1
        pub_choice = st.selectbox("厂商", pub_options, index=pub_idx)
    with p_col2:
        if pub_choice == "➕ 新增厂商...":
            final_publisher = st.text_input("新厂商", placeholder="输入新厂商", label_visibility="hidden", key="custom_pub")
        else:
            final_publisher = pub_choice

    # 游戏选择：置顶新增和未指定
    g_col1, g_col2 = st.columns(2)
    with g_col1:
        existing_games = [g for g in df[df["厂商"] == final_publisher]["游戏"].unique().tolist() if g != "未指定"]
        game_options = ["➕ 新增游戏...", "未指定"] + existing_games
        game_idx = game_options.index(st.session_state.last_game) if st.session_state.last_game in game_options else 1
        game_choice = st.selectbox("游戏", game_options, index=game_idx)
    with g_col2:
        if game_choice == "➕ 新增游戏...":
            final_game = st.text_input("新游戏", placeholder="输入新游戏", label_visibility="hidden", key="custom_game")
        else:
            final_game = game_choice

    # 项目选择：置顶新增和未指定
    i_col1, i_col2 = st.columns(2)
    with i_col1:
        existing_items = [i for i in df[df["游戏"] == final_game]["项目"].unique().tolist() if i != "未指定"]
        item_options = ["➕ 新增项目...", "未指定"] + existing_items
        item_idx = item_options.index(st.session_state.last_item) if st.session_state.last_item in item_options else 1
        item_choice = st.selectbox("项目", item_options, index=item_idx)
    with i_col2:
        if item_choice == "➕ 新增项目...":
            final_item = st.text_input("新项目", placeholder="如: 月卡, 皮肤", label_visibility="hidden", key="custom_item")
        else:
            final_item = item_choice

    st.write("")

    col_price, col_qty = st.columns(2)
    with col_price:
        price = st.number_input("单价", min_value=0.0, value=30.0, step=1.0, key="input_price")
    with col_qty:
        quantity = st.number_input("数量", min_value=1, value=1, step=1, key="input_qty")

    date = st.date_input("日期", datetime.date.today())
    note = st.text_input("备注 (选填)", key="input_note") 

    if st.button("💾 记入账本", use_container_width=True, type="primary"):
        if final_publisher and final_game and final_item:
            new_row = {
                "用户": current_user,
                "日期": date.strftime("%Y-%m-%d"),
                "厂商": final_publisher,
                "游戏": final_game,
                "项目": final_item,
                "单价": price,
                "数量": quantity,
                "总额": price * quantity,
                "备注": note
            }
            df = pd.concat([df, pd.DataFrame([new_row])], ignore_index=True)
            save_data(df)
            
            # 状态记忆
            st.session_state.last_user = current_user
            st.session_state.last_pub = final_publisher
            st.session_state.last_game = final_game
            st.session_state.last_item = final_item
            
            # 清空瞬时输入
            keys_to_clear = ["input_price", "input_qty", "input_note", "custom_user", "custom_pub", "custom_game", "custom_item"]
            for k in keys_to_clear:
                if k in st.session_state: del st.session_state[k]

            st.success("添加成功！")
            st.rerun()
        else:
            st.error("请确保厂商、游戏和项目已选择或输入！")

# 3. 主界面布局保持一致，增强筛选联动
user_df = df[df["用户"] == current_user]

if not user_df.empty:
    st.write("### 🔍 资产筛选器")
    filter_col1, filter_col2 = st.columns(2)
    
    with filter_col1:
        all_pubs = sorted(user_df["厂商"].unique().tolist())
        selected_pubs = st.multiselect("筛选厂商", options=all_pubs, default=all_pubs)
        
    with filter_col2:
        available_games = sorted(user_df[user_df["厂商"].isin(selected_pubs)]["游戏"].unique().tolist())
        selected_games = st.multiselect("筛选游戏", options=available_games, default=available_games)

    filtered_df = user_df[user_df["厂商"].isin(selected_pubs) & user_df["游戏"].isin(selected_games)]
    
    st.divider()

    if not filtered_df.empty:
        total_expense = filtered_df["总额"].sum()
        st.metric(label=f"当前筛选总支出 (RMB)", value=f"¥ {total_expense:.2f}")
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.write("**📊 厂商支出占比**")
            publisher_sum = filtered_df.groupby("厂商")["总额"].sum().reset_index()
            fig_pie1 = px.pie(publisher_sum, values="总额", names="厂商", hole=0.5, color_discrete_sequence=MODERN_COLORS)
            fig_pie1.update_traces(textposition='inside', textinfo='percent+label')
            fig_pie1.update_layout(margin=dict(t=10, b=10, l=0, r=0), legend=dict(orientation="h", yanchor="top", y=-0.1, xanchor="center", x=0.5)) 
            st.plotly_chart(fig_pie1, use_container_width=True, config={'displayModeBar': False})
            
        with col2:
            st.write("**🎮 游戏支出分布**")
            game_sum = filtered_df.groupby("游戏")["总额"].sum().reset_index()
            fig_pie2 = px.pie(game_sum, values="总额", names="游戏", hole=0.5, color_discrete_sequence=MODERN_COLORS[::-1])
            fig_pie2.update_traces(textposition='inside', textinfo='percent+label')
            fig_pie2.update_layout(margin=dict(t=10, b=10, l=0, r=0), legend=dict(orientation="h", yanchor="top", y=-0.1, xanchor="center", x=0.5))
            st.plotly_chart(fig_pie2, use_container_width=True, config={'displayModeBar': False})

        st.write("**🗂️ 流水明细 (💡双击单元格修改，选中左侧可删除/添加)**")
        
        edited_df = st.data_editor(
            filtered_df,
            column_config={
                "用户": None, 
                "总额": st.column_config.NumberColumn("总额", disabled=True),
                "日期": st.column_config.DateColumn("日期", format="YYYY-MM-DD")
            },
            num_rows="dynamic",
            use_container_width=True,
            hide_index=True,
            key="expense_editor"
        )
        
        if st.button("🔄 保存表格修改", type="secondary"):
            edited_df["用户"] = current_user
            edited_df["单价"] = pd.to_numeric(edited_df["单价"], errors='coerce').fillna(0)
            edited_df["数量"] = pd.to_numeric(edited_df["数量"], errors='coerce').fillna(1)
            edited_df["总额"] = edited_df["单价"] * edited_df["数量"]
            
            df_unchanged = df.drop(filtered_df.index)
            df_updated = pd.concat([df_unchanged, edited_df]).reset_index(drop=True)
            
            save_data(df_updated)
            st.success("📝 修改已成功保存！")
            st.rerun()

    else:
        st.warning("当前筛选条件下无流水记录。")
        
else:
    st.info(f"暂无 {current_user} 的消费数据。")