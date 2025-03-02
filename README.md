# Grok API 服务

## 项目简介
本项目提供了一个基于 Python 的 Grok API 服务，使用 OpenAI 的格式转换调用 grok 官网进行 API 处理。
注意事项，需要自己ip没有被屏蔽，运行失败有可能是这问题。

## 快速开始

### 1. 安装依赖
```bash
pip install -r requirements.txt
```

### 2. 配置环境变量
创建 `.env` 文件并配置以下环境变量：

```env
# 服务器配置
PORT=3000

# API 配置
API_KEY=sk-123456789

# 会话配置
IS_TEMP_CONVERSATION=false
IS_TEMP_GROK2=true
GROK2_CONCURRENCY_LEVEL=2

# 图床配置
TUMY_KEY=your_tumy_key  # 和 PICGO_KEY 二选一
# PICGO_KEY=your_picgo_key

# SSO 配置
IS_CUSTOM_SSO=false

# 显示配置
ISSHOW_SEARCH_RESULTS=false
SHOW_THINKING=true

# SSO 令牌配置 (多个令牌用英文逗号分隔)
SSO=your_sso_token1,your_sso_token2,your_sso_token3
```

### 3. 启动服务
```bash
python app.py
```

## 环境变量说明

|变量 | 说明 | 构建时是否必填 |示例|
|--- | --- | ---| ---|
|`IS_TEMP_CONVERSATION` | 是否开启临时会话，开启后会话历史记录不会保留在网页 | （可以不填，默认是false） | `true/false`|
|`IS_TEMP_GROK2` | 是否开启无限临时账号的grok2，关闭则grok2相关模型是使用你自己的cookie账号的次数 | （可以不填，默认是true） | `true/false`|
|`GROK2_CONCURRENCY_LEVEL` | grok2临时账号的并发控制，过高会被ban掉ip | （可以不填，默认是2） | `2`|
|`API_KEY` | 自定义认证鉴权密钥 | （可以不填，默认是sk-123456789） | `sk-123456789`|
|`PICGO_KEY` | PicGo图床密钥，与TUMY_KEY二选一 | 不填无法流式生图 | -|
|`TUMY_KEY` | TUMY图床密钥，与PICGO_KEY二选一 | 不填无法流式生图 | -|
|`ISSHOW_SEARCH_RESULTS` | 是否显示搜索结果 | （可不填，默认关闭） | `true/false`|
|`SSO` | Grok官网SSO Cookie，可以设置多个使用英文逗号分隔，代码会对不同账号的SSO自动轮询和均衡 | （除非开启IS_CUSTOM_SSO否则必填） | `sso1,sso2`|
|`PORT` | 服务部署端口 | （可不填，默认3000） | `3000`|
|`IS_CUSTOM_SSO` | 如果想自己来自定义号池来轮询均衡，而不是通过代码内置的号池逻辑系统来轮询均衡，可开启此选项。开启后 API_KEY 需要设置为请求认证用的 sso cookie，同时SSO环境变量失效 | （可不填，默认关闭） | `true/false`|
|`SHOW_THINKING` | 是否显示思考模型的思考过程 | （可不填，默认为true） | `true/false`|

## 功能特点
实现的功能：
1. 支持文字生成图，使用grok-2-imageGen和grok-3-imageGen模型
2. 支持全部模型识图和传图，只会识别存储用户消息最新的一个图，历史记录图全部为占位符替代
3. 支持搜索功能，使用grok-2-search或者grok-3-search模型，可以选择是否关闭搜索结果
4. 支持深度搜索功能，使用grok-3-deepsearch
5. 支持推理模型功能，使用grok-3-reasoning
6. 支持真流式，上面全部功能都可以在流式情况调用
7. 支持多账号轮询，在环境变量中配置
8. grok2采用临时账号机制，理论无限调用，也可以使用自己账号的grok2
9. 可以选择是否移除思考模型的思考过程
10. 支持自行设置轮询和负载均衡，而不依靠项目代码
11. 已转换为openai格式

### 可用模型列表
- `grok-2`
- `grok-2-imageGen`
- `grok-2-search`
- `grok-3`
- `grok-3-search`
- `grok-3-imageGen`
- `grok-3-deepsearch`
- `grok-3-reasoning`

### 模型可用次数参考
- grok-2, grok-2-imageGen, grok-2-search 合计：20次  每2小时刷新
- grok-3, grok-3-search, grok-3-imageGen 合计：20次  每2小时刷新
- grok-3-deepsearch：10次 每24小时刷新
- grok-3-reasoning：10次 每24小时刷新

### cookie的获取办法：
1. 打开[grok官网](https://grok.com/)
2. 复制SSO的cookie值填入SSO变量即可
![SSO cookie获取方法](https://github.com/user-attachments/assets/539d4a53-9352-49fd-8657-e942a94f44e9)

### API调用
- 模型列表：`/v1/models`
- 对话：`/v1/chat/completions`

## 补充说明
- 如需使用流式生图的图像功能，需在[tumy图床](https://tu.my/)申请API Key
- 自动移除历史消息里的think过程，同时如果历史消息里包含里base64图片文本，而不是通过文件上传的方式上传，则自动转换为[图片]占用符

## 注意事项
⚠️ 本项目仅供学习和研究目的，请遵守相关使用条款。

## 致谢
本项目基于 [xLmiler/grok2api](https://github.com/xLmiler/grok2api) ，在此特别感谢原作者的贡献。

