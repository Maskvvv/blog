# python-dotenv：把密钥从代码里"搬出去"的优雅方式

> 你有没有在代码里写过 `api_key = "sk-xxx"` 这样的硬编码？有没有不小心把密钥推到 GitHub 上过？`python-dotenv` 就是来解决这个问题的。

## 一、它是什么？

`python-dotenv` 的作用就一句话：**把 `.env` 文件里的键值对加载到 `os.environ` 中。**

这样你就可以用 `os.getenv("KEY")` 来读取配置，而不用把密钥硬编码在代码里。

```python
from dotenv import load_dotenv
import os

load_dotenv()  # 加载 .env 文件

api_key = os.getenv("OPENAI_API_KEY")  # ✅ 从环境变量读取
```

## 二、原理：它做了什么？

核心逻辑非常简单，三步走：

```
第一步：找到 .env 文件
  ↓  默认从当前目录往上找，找到第一个 .env 为止

第二步：逐行解析
  ↓  KEY=VALUE → 去掉注释、去空格、处理引号

第三步：写入 os.environ
  ↓  os.environ["KEY"] = "VALUE"
```

用伪代码表示：

```python
def load_dotenv():
    # 1. 找文件
    env_file = find_file(".env")

    # 2. 逐行解析
    for line in open(env_file):
        line = line.strip()
        if not line or line.startswith("#"):  # 跳过空行和注释
            continue
        key, value = line.split("=", 1)       # 只切第一个 =
        key = key.strip()
        value = value.strip().strip('"').strip("'")  # 去引号

        # 3. 写入环境变量
        os.environ[key] = value
```

就是这么朴实无华。

## 三、为什么需要它？

### 问题：密钥硬编码

```python
# 😱 千万别这样！代码推到 GitHub，Key 就泄露了
client = OpenAI(api_key="sk-21pn")
```

### 解决：.env 文件

```bash
# .env 文件（加入 .gitignore，不提交到 Git）
OPENAI_API_KEY=sk-21pn
BASE_URL=https://api.moonshot.cn/v1
```

```python
# 代码里只读环境变量，密钥不出现在代码中
from dotenv import load_dotenv
import os

load_dotenv()
client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY"),
    base_url=os.getenv("BASE_URL"),
)
```

即使代码分享给别人，密钥也不会泄露。

## 四、.env 文件语法

`.env` 文件支持丰富的语法：

```bash
# 注释
# 这是注释
OPENAI_API_KEY=sk-xxx  # 行尾注释

# 引号（推荐，避免特殊字符问题）
NAME="hello world"
NAME='hello world'

# 多行值
PRIVATE_KEY="-----BEGIN KEY-----
abc123
-----END KEY-----"

# 变量引用
BASE_DIR=/app
LOG_DIR=${BASE_DIR}/logs

# 空值
EMPTY_VAR=

# 展开环境变量
DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5432/mydb
```

## 五、核心 API

### 1. `load_dotenv()` —— 加载 .env 文件

```python
# 默认自动找
load_dotenv()

# 指定路径
load_dotenv("/path/to/my.env")
```

### 2. `override` 参数 —— 是否覆盖已有环境变量

```python
# 默认不覆盖（系统环境变量优先）
load_dotenv()                # os.environ 已有的不会被覆盖

# 强制覆盖
load_dotenv(override=True)   # .env 里的值会覆盖系统环境变量
```

优先级：**系统环境变量 > .env 文件**（默认行为）

```
系统环境变量：OPENAI_API_KEY=sk-aaa
.env 文件：   OPENAI_API_KEY=sk-bbb

load_dotenv()              → os.getenv() 得到 "sk-aaa"（系统优先）
load_dotenv(override=True) → os.getenv() 得到 "sk-bbb"（.env 覆盖）
```

### 3. `find_dotenv()` —— 自动查找文件

```python
from dotenv import load_dotenv, find_dotenv

# 从当前目录往上找，直到找到 .env
load_dotenv(find_dotenv())

# 从脚本所在目录开始找
load_dotenv(find_dotenv(usecwd=True))
```

### 4. 命令行用法

```bash
# 不改代码，临时用 .env 里的变量运行脚本
dotenv run python my_script.py
```

## 六、实战：多环境配置

实际项目中，我们通常有多个环境（开发、测试、生产），每个环境配置不同：

```
项目目录：
├── .env                # 公共配置
├── .env.development    # 开发环境
├── .env.production     # 生产环境
├── .env.test           # 测试环境
```

```python
import os
from dotenv import load_dotenv

# 先加载公共配置
load_dotenv(".env")

# 再加载环境特定配置（覆盖公共配置）
env = os.getenv("APP_ENV", "development")
load_dotenv(f".env.{env}", override=True)
```

## 七、环境变量的完整优先级

```
优先级从高到低：

1. 系统环境变量     → Windows: 系统设置 / Linux: export
2. .env 文件        → load_dotenv() 加载
3. 代码默认值       → os.getenv("KEY", "default")
```

三层兜底的写法：

```python
api_key = os.getenv("OPENAI_API_KEY")  # 1. 先看系统环境变量
if not api_key:
    load_dotenv()                       # 2. 再看 .env 文件
    api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    api_key = "default-key"             # 3. 最后用默认值
```

## 八、最佳实践

### 1. 一定要把 `.env` 加入 `.gitignore`

```gitignore
# .gitignore
.env
.env.*
```

### 2. 提供示例文件

```bash
# .env.example（提交到 Git，告诉别人需要哪些变量）
OPENAI_API_KEY=your-api-key-here
BASE_URL=https://api.openai.com/v1
```

### 3. 不要在日志中打印环境变量

```python
# 😱 别这样
print(f"Using API Key: {os.getenv('OPENAI_API_KEY')}")

# 😊 这样就好
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("OPENAI_API_KEY not set")
```

### 4. 生产环境用系统环境变量

生产环境（Docker、K8s）通常直接注入系统环境变量，不需要 `.env` 文件：

```yaml
# docker-compose.yml
services:
  app:
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
```

## 九、一句话总结

> `load_dotenv()` = 把 `.env` 文件里的键值对塞进 `os.environ`，让你用 `os.getenv()` 就能读到，不用手动设环境变量，也不用把密钥硬编码在代码里。

简单、实用、优雅。
