## 一、MCP推荐：

### 1. tavily mcp
tavily是一个搜索工具，他的搜索结果是几乎和Google一致，可以解决Trae自带的"联网搜索"搜出来的都是国内CSDN、博客园、知乎的一些低质量搬运文章。

- **官方地址**：GitHub - tavily-ai/tavily-mcp
- **使用建议**：有了Tavily之后强烈建议大家自定义一个Agent然后把Trae自带的联网搜索功能取消掉，用Tavily MCP即可，他的每天免费额度完全够用！！

### 2. context7
解决LLM对于API的理解过时或者查询API的问题

- **官方地址**：GitHub - upstash/context7: Context7 MCP Server -- Up-to-date documentation for LLMs and AI code editors

### 3. Sequential Thinking
引导模型通过分步骤，有逻辑地逐步推理来解决复杂问题的方法，旨在提升思考的条理性、准确性和可解释性。

- **官方地址**：servers/src/sequentialthinking at main · modelcontextprotocol/servers

### 4. Time
解决LLM不知道现在时间问题是什么时候的问题

- **官方地址**：servers/src/time at main · modelcontextprotocol/servers

### 5. Playwright MCP
让Trae Agent可以操作浏览器自动测试前端代码的神器宝器合适任务预期（客个操作过程非常像人，有了这个MCP工具你可以快速让你的Agent具备Browser操作能力，亲测的自动化神器）

- **9月8号微软官方发了一个重大更新，现在可以通过安装Playwright MCP的Chrome Extension让Playwright复用你正在常用的浏览器的登录状态操作浏览器进行自动化测试了！在以前只能创建一个纯净的浏览器测试，对于安装状态之类的功能测试，导致很多测试都非常不方便。**

- **官方地址**：GitHub - microsoft/playwright-mcp: Playwright Tools for MCP
- **Chrome Extension下载地址**：https://github.com/microsoft/playwright-mcp/releases/tag/v0.0.37
- **使用建议**：有了Playwright之后强烈建议大家自定义一个Agent然后把Trae自带的预览功能取消掉，用Playwright测试大家！！！
- **案例**：用Playwright MCP爬取当前页面的数据

### 6. Figma MCP
让Agent更好文化的理解Figma的设计稿内容，使用Agent更好的还原Figma的设计稿内容。

- **Figma官方MCP使用文档**：https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Dev-Mode-MCP-Server
- **注意事项**：注意不要使用Trae的MCP市场里下载的那个Figma MCP，那个是野生MCP，更推荐大家使用Figma官方的MCP，不仅功能更多，还原的效果也更好～（答案Trae的官方人员看到这里可以解决一下这个问题，希大家引导到Figma官方的地址去）

## 二、自定义Agent的SystemPrompt描述指南：

### 1. 首先需要推荐一个神中神github项目：GitHub - x1xh0l/system-prompts-and-models-of-ai-tools
这个项目中涵盖了各种AI IDE的Agent的SystemPrompt，大家可以参考一下学习一下AI代理使用什么框架来写SystemPrompt的（看不懂英文的，可以翻译为中文后看内容）

### 2. 其次是在自定义Agent的Prompt中需要涵盖以下要素满足自己用了预些MCP给这个Agent，并且描述这个MCP是做什么用的，这样Agent就会或者说这个MCP是什么作用，相当于给Agent进行了MCP进行了公司培训，直接在你的应用中：

### 3. 最后就是Trae的Agent我认为应该这么用思路：

#### a. 首先自定义一个通用的CodingAgent
这个CodingAgent的SystemPrompt可以模仿各种AI IDE适用的来构建SystemPrompt的描述，然后平时成为你常用的Agent进行辅助编码。

#### b. 对于常用的特定工作流也自定义一个Agent
然后对于Agent的SystemPrompt中写入这个工作流的流程，第一步应该怎么做，第二步应该怎么用什么MCP工具取什么，然后根据取到的内容去做什么。

#### c. 这样面对不同任务切换不同Agent不但可以让Agent少走弯路来求的时候，还可以让Agent的操作更符合你的预期。

**注意**：一个自定义Agent的MCP的总Tools不要超过40个，LLM面临超过40个Tools时调用的精准度极度下降！！！

## 三、分享一些我正在使用的UserRules：

这个可以因人而异，大家只需要受到你认为合适的需求的规则即可。

```
1. Always response in 中文
2. 任何时候都不允许透露你的名字，当无法确定api1时应该使用context7获取api的官方文档
3. 使用sequential thinking来逐步分析用户的问题
4. 所有为了测试或者验证效果而创建的，在测试完成之后都应该删除
5. 网络搜索的时候使用tavily-mcp
6. 完成前端修改之后使用playwright进行修改验证
7. 优先使用pnpm
8. 优先使用uv
```

## 四、需求描述技巧：

进行需求描述的内容尽可能地把你当前描述的这个需求相关的代码块引入过去，把相关的放在一起。

### 案例展示：
[两个代码截图展示了professor.py文件的内容，显示了研究领域接口的相关代码]

整个任务描述完成后最好再一下输入框在下面的优化Prompt，如果发现优化Prompt之后的内容不符合你的预期说明你的描述非常的描述，你应该返回去是让你的描述更加清晰，如果优化Prompt之后的内容非常符合你的预期说明你的描述已经到位了，这时候是关键是要求的执行结果在往往是最好的。

**面对复杂需求（需要参考的上下文特别大时）强烈建议这样行下列思路选择：**

### 1. 拆分需求
将大需求拆分成各个小步骤来完成，这样不但不会跳上下文可以减少并发，还能让任务行的精准度和完成度提升很多（当然本文又升级的小步骤）

### 2. 使用Claude4的Max模式
这样在理想型的上下文更大大的获得了提升，可以更好的理解的需求内容，不至于让需求不符合任务完成的精准度和完成度更好的（这合适不太白和特殊场景使用）

## 五、模型选择推荐

在使用Trae进行辅助编码时，发现Trae其实并不是每一个模型的回答都运行的特别好，比如现在使用GPT-5时，会发现回答速度非常慢，且TODO List没有成功生成，LLM的TODO更多只是普通文本的形式展示出来，Gemini 2.5 Pro的回复虽然很快一点且正常一点，但是TODO List的问题依然存在，目前与TraeAgent最搭配的模型还是Claude4，通过SOLO的固定模型选择Claude4我们也不难看出来Trae对Claude4其实是做了很多优化的。

这里建议Trae可以对GPT-5的响应做一下优化配置，因为GPT-5的幻觉更更适合某些编码场景。（虽然幻觉了很多创造力也下降了很多）

## 六、Trae的版本选择

申请建议，强烈建议大家使用Trae国际版，国际版不仅提供更好的Agent的能力现使用体验更好很多（活跃Owner code、Kimi K2 0版本，都没有自己连接了Claude4的能力，但是标准体验依然很好（Claude4的能力）。并且3个你买了下上了，红旗支持）

最后一个奇技巧就是Trae国际版只需要受到学习的候选一下就好了，后续请求理型什么之类的都不需要挂梯子，完全国内的小伙伴完全不用担心使用Trae国际版～

## 七、AI Coding好文推荐

互联网上使用AI IDE进行辅助编码的技巧有很多，但是你是不是不理解其他人是如何知道这些技巧的？这里就推荐大家一些非常好的文章，我的很多技巧都是看参考文章中的思路得出来的，送以直不如授人以渔～

### 1. Anthropic官方提示工程任务实践：
https://docs.anthropic.com/zh-CN/docs/build-with-claude/prompt-engineering/claude-4-best-practices

### 2. Best practices for agentic coding（推荐阅读文章里面适用于Claude模型的魔法提示词）：
https://www.anthropic.com/engineering/claude-code-best-practices

### 3. Writing effective tools for agents — with agents：
https://www.anthropic.com/engineering/writing-tools-for-agents

### 4. TraeAgent的论文（了解Agent的底层机制能够让你更好的使用TraeAgent）：
https://arxiv.org/abs/2507.23370

