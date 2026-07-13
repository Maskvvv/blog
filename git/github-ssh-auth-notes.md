# GitHub 推送认证与 SSH 密钥说明

## 问题背景

在本地执行 `git push` 时，出现如下报错：

```text
remote: Invalid username or token. Password authentication is not supported for Git operations.
fatal: Authentication failed for 'https://github.com/Maskvvv/blog.git/'
```

这个报错说明：当前仓库使用的是 HTTPS 地址推送到 GitHub，但 GitHub 已经不支持用账号密码进行 Git 操作认证。现在需要改用 Personal Access Token，或者改用 SSH 密钥认证。

当前 remote 地址类似：

```text
https://github.com/Maskvvv/blog.git/
```

## 解决方式

### 方式一：继续使用 HTTPS

如果继续使用 HTTPS，需要使用 GitHub 的 Personal Access Token，而不是 GitHub 登录密码。

如果已安装 GitHub CLI，可以执行：

```powershell
gh auth login
gh auth setup-git
git push
```

如果不使用 GitHub CLI，可以在 GitHub 创建一个 Personal Access Token：

```text
GitHub -> Settings -> Developer settings -> Personal access tokens -> Fine-grained token
```

给目标仓库，例如 `Maskvvv/blog`，授予 `Contents: Read and write` 权限。

如果 Windows 里缓存了旧的错误密码，可以清除 GitHub 的旧凭据：

```powershell
"protocol=https`nhost=github.com`n" | git credential-manager erase
git push
```

再次提示输入账号密码时：

```text
Username: GitHub 用户名
Password: 粘贴刚创建的 token
```

这里的 `Password` 不是 GitHub 登录密码，而是 Personal Access Token。

### 方式二：改用 SSH

更推荐使用 SSH。配置一次后，之后推送通常不需要反复处理 token 或密码缓存。

生成新的 SSH 密钥：

```powershell
ssh-keygen -t ed25519 -C "你的邮箱"
```

一路回车即可。生成后通常会得到：

```text
id_ed25519
id_ed25519.pub
```

其中：

- `id_ed25519` 是私钥，只能保存在自己的电脑上，不能发给别人。
- `id_ed25519.pub` 是公钥，可以添加到 GitHub 的 SSH keys 中。

查看公钥内容：

```powershell
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub
```

然后把输出内容添加到 GitHub：

```text
GitHub -> Settings -> SSH and GPG keys -> New SSH key
```

把仓库 remote 改成 SSH：

```powershell
cd D:\资料\blog
git remote set-url origin git@github.com:Maskvvv/blog.git
ssh -T git@github.com
git push
```

如果测试成功，会看到类似：

```text
Hi Maskvvv! You've successfully authenticated, but GitHub does not provide shell access.
```

这表示 SSH key 已经被 GitHub 识别，可以用于 Git 操作。

## ed25519 是什么意思

`ed25519` 是一种 SSH 密钥算法。

在命令中：

```powershell
ssh-keygen -t ed25519 -C "你的邮箱"
```

`-t ed25519` 的意思是生成 Ed25519 类型的 SSH 密钥。

Ed25519 是现在比较推荐的新密钥算法，特点是：

- 安全性高。
- 密钥较短。
- 速度快。
- GitHub、Git、OpenSSH 都支持。
- 比老式的 RSA 更适合作为新生成的 SSH key。

## 一台电脑可以有多对 SSH 密钥吗

可以。一台电脑中存在多对 SSH 密钥是很正常的，不会天然有问题。

例如 `.ssh` 目录中可能同时存在：

```text
id_ed25519
id_ed25519.pub
id_rsa
id_rsa.pub
known_hosts
known_hosts.old
```

这里有两对密钥：

```text
私钥：id_ed25519
公钥：id_ed25519.pub
```

```text
私钥：id_rsa
公钥：id_rsa.pub
```

说明：

- `.pub` 结尾的是公钥，可以放到 GitHub、服务器或云主机后台。
- 没有 `.pub` 后缀的是私钥，只能留在自己电脑上。
- `id_rsa` 是较老的 RSA 算法。
- `id_ed25519` 是较新的算法，现在更推荐。

建议保留旧的 `id_rsa`，不要随意删除；把新的 `id_ed25519.pub` 添加到 GitHub；以后 GitHub 使用新的 `id_ed25519`。

## 多对密钥时 SSH 会怎么选择

当执行：

```powershell
ssh -T git@github.com
```

SSH 通常会读取配置文件：

```text
C:\Users\lenovo\.ssh\config
```

如果配置文件里明确指定了密钥，例如：

```sshconfig
IdentityFile ~/.ssh/id_ed25519
```

SSH 会优先使用指定的密钥。

如果没有明确指定，SSH 会尝试默认名称的密钥，例如：

```text
~/.ssh/id_rsa
~/.ssh/id_ecdsa
~/.ssh/id_ecdsa_sk
~/.ssh/id_ed25519
~/.ssh/id_ed25519_sk
```

如果启用了 `ssh-agent`，SSH 也可能会尝试 agent 中已经加载的密钥。

也就是说，在存在多对密钥的情况下，SSH 通常会挨个尝试可用密钥。

## 多密钥可能遇到的问题

有些服务会限制认证尝试次数。如果电脑里密钥很多，SSH 还没试到正确的那一把，服务器可能就先拒绝了。

可能出现类似报错：

```text
Too many authentication failures
```

这种情况下，最好在 SSH 配置文件中明确指定 GitHub 使用哪一把密钥。

## 推荐的 GitHub SSH 配置

创建或编辑文件：

```text
C:\Users\lenovo\.ssh\config
```

加入：

```sshconfig
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
```

含义：

- `Host github.com`：这段配置用于连接 GitHub。
- `HostName github.com`：真实连接的主机名。
- `User git`：GitHub SSH 固定使用 `git` 用户。
- `IdentityFile ~/.ssh/id_ed25519`：指定使用这把私钥。
- `IdentitiesOnly yes`：只使用指定的密钥，不把 agent 里的其他密钥都拿出来尝试。

配置完成后测试：

```powershell
ssh -T git@github.com
```

成功后再执行：

```powershell
git push
```

## 总结

GitHub 不再支持账号密码进行 Git 推送认证。如果仓库使用 HTTPS，需要改用 Personal Access Token；更推荐的做法是改用 SSH。

一台电脑里可以有多对 SSH 密钥。多密钥本身没问题，但为了避免 SSH 尝试错密钥或触发认证次数限制，建议在 `~/.ssh/config` 中为 GitHub 明确指定 `id_ed25519`。
