# 仓库标注任务结果 - 3395

## 1. 仓库基本信息

- **repo_url**: yuwangi/longmao-repo-template (Internal ID: 3395)
- **repo_type**: 私有仓库
- **language**: Java 17 (SSM) + React (Vite)
- **task_count**: 20
- **dockerfile**: [见下文 Dockerfile 详情]

## 2. 环境说明 (environment_notes)

该环境采用全栈单容器方案。Dockerfile 已集成了 MySQL 8.0、OpenJDK 17 (搭配 Tomcat 9 部署) 及 Nginx 环境。构建镜像后，启动脚本会自动完成数据库初始化、Maven 打包编译以及前端生产构建。

**验证步骤**：
1. **构建镜像**：`docker build -t app-3395 .`
2. **运行容器**：`docker run -d -p 33395:33395 -p 13395:13395 --name student-sys app-3395`
3. **访问地址**：
   - 前端门户：[http://localhost:33395](http://localhost:33395)
   - 后端接口：[http://localhost:13395/api](http://localhost:13395/api) (Nginx 代理到 8080 端口)
4. **工作目录**：`/app`

## 3. Dockerfile 详情

```dockerfile
# 使用 Ubuntu 作为基础镜像，构建全栈一键运行环境
FROM ubuntu:22.04

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 安装必要的技术栈
RUN apt-get update && apt-get install -y \
    curl \
    openjdk-17-jdk \
    mysql-server \
    nginx \
    maven \
    tomcat9 \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . ./

# 构建后端
RUN cd backend && mvn package -DskipTests

# 构建前端
RUN cd frontend && \
    npm config set registry https://registry.npmmirror.com && \
    npm install && \
    npm run build

# 配置 Nginx (监听非标端口 33395 和 13395)
RUN echo 'server { \
    listen 33395; \
    location / { \
        root /app/frontend/dist; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
    location /api/ { \
        proxy_pass http://127.0.0.1:8080/api/; \
    } \
} \
server { \
    listen 13395; \
    location / { \
        proxy_pass http://127.0.0.1:8080/; \
    } \
}' > /etc/nginx/sites-available/default

# 启动脚本
RUN echo "#!/bin/bash\n\
service mysql start\n\
mysql -u root -e \"CREATE DATABASE IF NOT EXISTS ssm_student_db;\"\n\
mysql -u root ssm_student_db < /app/backend/init.sql\n\
cp /app/backend/target/*.war /var/lib/tomcat9/webapps/ROOT.war\n\
service tomcat9 start\n\
service nginx start\n\
tail -f /var/log/nginx/access.log" > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

EXPOSE 33395 13395
ENTRYPOINT ["/app/entrypoint.sh"]
```

## 4. 任务列表

### 任务 1: 后端登录鉴权逻辑分析
- **Prompt**: 请分析 `com.student.controller.AuthController` 中的 `login` 方法，说明它是如何验证用户凭据并与 `com.student.service.impl.UserServiceImpl` 交互的，以及登录成功后返回的 Token 是在哪个环节生成的？
- **难度**: 简单
- **类别**: 代码理解与分析
- **技术栈**: Java, Spring MVC
- **功能模块**: 后端, 安全

### 任务 2: 学生实体增加住址字段
- **Prompt**: 修改 `com.student.entity.Student` 类和 `init.sql` 脚本，增加 `address`（家庭住址）字段。同步更新 `StudentMapper.xml` 中的 `insert` 和 `update` 标签，并在 `StudentList.jsx` 的编辑弹窗中增加该输入项。
- **难度**: 中等
- **类别**: 功能迭代
- **技术栈**: Java, MyBatis, React
- **功能模块**: 全栈, 学生管理

### 任务 3: 班级删除的前置校验
- **Prompt**: 在 `com.student.service.impl.ClazzServiceImpl` 的 `deleteClazz` 方法中增加逻辑：先调用 `studentMapper.count` 检查该班级下是否还有学生，如果是则禁止删除并抛出一个自定义的运行时异常。
- **难度**: 中等
- **类别**: Bug 修复 / 调试
- **技术栈**: Java, Spring
- **功能模块**: 后端, 班级管理

### 任务 4: 登录态持久化处理
- **Prompt**: 目前前端刷新页面后登录态会消失。请修改 `frontend/src/store/useAuthStore.js`，引入 Zustand 的 `persist` 中间件，将 `user` 信息持久化到 `localStorage` 中。
- **难度**: 简单
- **类别**: 代码重构
- **技术栈**: React, Zustand
- **功能模块**: 前端, 状态管理

### 任务 5: 分页逻辑单元测试
- **Prompt**: 为 `com.student.service.impl.StudentServiceImpl` 编写 JUnit 单元测试，使用 Mockito 模拟 `StudentMapper` 的返回结果，验证 `getStudentList` 方法在不同 `page` 和 `limit` 参数下的 `offset` 计算是否正确。
- **难度**: 中等
- **类别**: 测试
- **技术栈**: Java, JUnit, Mockito
- **功能模块**: 后端, 测试

### 任务 6: 数据库持久化方案优化
- **Prompt**: 修改项目根目录下的 `Dockerfile`，为 MySQL 数据库目录 `/var/lib/mysql` 设置一个 VOLUME 挂载点，并说明如何在 `docker run` 命令中映射物理路径以确保数据持久化。
- **难度**: 简单
- **类别**: DevOps / 工程化
- **技术栈**: Docker, MySQL
- **功能模块**: 运维, 数据库

### 任务 7: 学生成绩雷达图展示
- **Prompt**: 在 `StudentList.jsx` 的学生详情弹窗中，使用 `recharts` 库增加一个雷达图（Radar Chart），展示该学生在不同课程（来自 `scores` 表）中的成绩分布。
- **难度**: 困难
- **类别**: 功能迭代
- **技术栈**: React, Recharts
- **功能模块**: 前端, 数据可视化

### 任务 8: 搜索功能联合查询优化
- **Prompt**: 优化 `StudentMapper.xml` 中 `id="findByPage"` 的 SQL 语句，使其支持对 `name` 和 `student_no` 的联合模糊搜索，并确保搜索条件为空时能正确返回所有数据。
- **难度**: 简单
- **类别**: 功能迭代
- **技术栈**: MyBatis, SQL
- **功能模块**: 后端, 搜索

### 任务 9: 角色访问权限控制 (RBAC)
- **Prompt**: 在后端实现一个简单的权限拦截器（Interceptor），当当前用户角色为 `TEACHER` 时，禁止其访问 `ClazzController` 中带有 `@DeleteMapping` 注解的接口。
- **难度**: 中等
- **类别**: 功能迭代
- **技术栈**: Spring MVC, Java
- **功能模块**: 后端, 权限管理

### 任务 10: 表格加载骨架屏实现
- **Prompt**: 在 `frontend/src/pages/StudentList.jsx` 中，当 `loading` 状态为 `true` 时，渲染一个骨架屏（Skeleton）列表，而非仅仅显示加载图标，以提升视觉平滑度。
- **难度**: 简单
- **类别**: 功能迭代
- **技术栈**: React, Tailwind CSS
- **功能模块**: 前端, 用户体验

### 任务 11: 实现学生批量删除功能
- **Prompt**: 在 `StudentMapper.xml` 中使用 `<foreach>` 标签实现 `batchDelete` 接口。同时在前端 `StudentList.jsx` 的表格头部增加一个全选复选框，支持用户一键删除选中的多个学生。
- **难度**: 中等
- **类别**: 功能迭代
- **技术栈**: MyBatis, React
- **功能模块**: 全栈, 批量操作

### 任务 12: 后端入参合法性校验
- **Prompt**: 修复 `com.student.controller.StudentController` 中的潜在问题：在 `add` 接口中，若 `student.getPhone()` 不符合 11 位数字格式，应返回 `400 Bad Request` 和具体的报错原因。
- **难度**: 简单
- **类别**: Bug 修复 / 调试
- **技术栈**: Spring MVC, Java
- **功能模块**: 后端, 数据校验

### 任务 13: 接口地址环境变量化
- **Prompt**: 修改 `frontend/src/api/index.js`，将硬编码的 `baseURL` 提取到 Vite 的环境变量（`.env`）中，确保在开发和生产环境下能自动切换后端地址。
- **难度**: 简单
- **类别**: 代码重构
- **技术栈**: Vite, React
- **功能模块**: 前端, 工程化

### 14: 班级人数实时统计
- **Prompt**: 修改 `com.student.service.impl.StudentServiceImpl` 的 `getStatistics` 方法，通过联表查询统计每个班级的平均分并返回。前端 `Dashboard.jsx` 需新增一个饼图展示。
- **难度**: 中等
- **类别**: 功能迭代
- **技术栈**: MyBatis, React
- **功能模块**: 全栈, 统计分析

### 任务 15: 统一 API 返回格式重构
- **Prompt**: 创建一个通用的 `com.student.common.Result<T>` 类（包含 code, message, data 字段）。重构所有的 Controller 方法，使其统一返回该对象，提升接口一致性。
- **难度**: 简单
- **类别**: 代码重构
- **技术栈**: Java, Spring
- **功能模块**: 后端, 架构优化

### 任务 16: 搜索框输入防抖逻辑
- **Prompt**: 分析并重写 `StudentList.jsx` 中的搜索逻辑。解释目前的 `debouncedSearch` 是如何通过 `useEffect` 和 `setTimeout` 实现特性的，并讨论如果移除 `clearTimeout` 会导致什么后果。
- **难度**: 简单
- **类别**: 代码理解与分析
- **技术栈**: React, JavaScript
- **功能模块**: 前端, 性能优化

### 任务 17: 自定义 404 错误页面
- **Prompt**: 在 `frontend/src/main.jsx` 的 React Router 配置中，添加一个 Catch-all 路由，当用户访问不存在的路径时，展示一个具有“回到首页”按钮的美化 404 页面。
- **难度**: 简单
- **类别**: 功能迭代
- **技术栈**: React Router
- **功能模块**: 前端, 路由

### 任务 18: Tailwind 主题颜色自定义
- **Prompt**: 修改 `frontend/tailwind.config.js`，在 `extend` 中添加一组品牌色 `brand: { 500: '#...' }`。随后将 `StudentList.jsx` 中所有蓝色按钮的 `bg-blue-600` 替换为自定义的品牌色。
- **难度**: 简单
- **类别**: 功能迭代
- **技术栈**: Tailwind CSS
- **功能模块**: 前端, 样式系统

### 任务 19: 学生列表导出为 CSV 文件
- **Prompt**: 在 `StudentController` 中实现一个 `/export` 接口。使用 `OutputStream` 将 `studentService.getAllStudents()` 的结果以 CSV 字符流的形式输出，支持浏览器点击下载。
- **难度**: 中等
- **类别**: 功能迭代
- **技术栈**: Java, Spring MVC
- **功能模块**: 后端, 导出功能

### 任务 20: MyBatis 嵌套结果映射分析
- **Prompt**: 分析 `StudentMapper.xml` 中的 `findById` 标签。目前通过 `LEFT JOIN` 一次性查出班级名。请尝试将其重构为使用 `<association>` 标签的嵌套查询方式，并对比两者的执行效率。
- **难度**: 简单
- **类别**: 代码理解与分析
- **技术栈**: MyBatis
- **功能模块**: 后端, 持久层

---

## 5. 表格快速复制区 (Tab 分隔)

1	请分析 com.student.controller.AuthController 中的 login 方法，说明它是如何验证用户凭据并与 com.student.service.impl.UserServiceImpl 交互的，以及登录成功后返回的 Token 是在哪个环节生成的？	简单	代码理解与分析	Java, Spring MVC	后端, 安全
2	修改 com.student.entity.Student 类和 init.sql 脚本，增加 address（家庭住址）字段。同步更新 StudentMapper.xml 中的 insert 和 update 标签，并在 StudentList.jsx 的编辑弹窗中增加该输入项。	中等	功能迭代	Java, MyBatis, React	全栈, 学生管理
3	在 com.student.service.impl.ClazzServiceImpl 的 deleteClazz 方法中增加逻辑：先调用 studentMapper.count 检查该班级下是否还有学生，如果是则禁止删除并抛出一个自定义的运行时异常。	中等	Bug 修复 / 调试	Java, Spring	后端, 班级管理
4	目前前端刷新页面后登录态会消失。请修改 frontend/src/store/useAuthStore.js，引入 Zustand 的 persist 中间件，将 user 信息持久化到 localStorage 中。	简单	代码重构	React, Zustand	前端, 状态管理
5	为 com.student.service.impl.StudentServiceImpl 编写 JUnit 单元测试，使用 Mockito 模拟 StudentMapper 的返回结果，验证 getStudentList 方法在不同 page 和 limit 参数下的 offset 计算是否正确。	中等	测试	Java, JUnit, Mockito	后端, 测试
6	修改项目根目录下的 Dockerfile，为 MySQL 数据库目录 /var/lib/mysql 设置一个 VOLUME 挂载点，并说明如何在 docker run 命令中映射物理路径以确保数据持久化。	简单	DevOps / 工程化	Docker, MySQL	运维, 数据库
7	在 StudentList.jsx 的学生详情弹窗中，使用 recharts 库增加一个雷达图（Radar Chart），展示该学生在不同课程（来自 scores 表）中的成绩分布。	困难	功能迭代	React, Recharts	前端, 数据可视化
8	优化 StudentMapper.xml 中 id="findByPage" 的 SQL 语句，使其支持对 name 和 student_no 的联合模糊搜索，并确保搜索条件为空时能正确返回所有数据。	简单	功能迭代	MyBatis, SQL	后端, 搜索
9	在后端实现一个简单的权限拦截器（Interceptor），当当前用户角色为 TEACHER 时，禁止其访问 ClazzController 中带有 @DeleteMapping 注解的接口。	中等	功能迭代	Spring MVC, Java	后端, 权限管理
10	在 frontend/src/pages/StudentList.jsx 中，当 loading 状态为 true 时，渲染一个骨架屏（Skeleton）列表，而非仅仅显示加载图标，以提升视觉平滑度。	简单	功能迭代	React, Tailwind CSS	前端, 用户体验
11	在 StudentMapper.xml 中使用 <foreach> 标签实现 batchDelete 接口。同时在 frontend/src/pages/StudentList.jsx 的表格头部增加一个全选复选框，支持用户一键删除选中的多个学生。	中等	功能迭代	MyBatis, React	全栈, 批量操作
12	修复 com.student.controller.StudentController 中的潜在问题：在 add 接口中，若 student.getPhone() 不符合 11 位数字格式，应返回 400 Bad Request 和具体的报错原因。	简单	Bug 修复 / 调试	Spring MVC, Java	后端, 数据校验
13	修改 frontend/src/api/index.js，将硬编码的 baseURL 提取到 Vite 的环境变量（.env）中，确保在开发和生产环境下能自动切换后端地址。	简单	代码重构	Vite, React	前端, 工程化
14	修改 com.student.service.impl.StudentServiceImpl 的 getStatistics 方法，通过联表查询统计每个班级的平均分并返回。前端 Dashboard.jsx 需新增一个饼图展示。	中等	功能迭代	MyBatis, React	全栈, 统计分析
15	创建一个通用的 com.student.common.Result<T> 类（包含 code, message, data 字段）。重构所有的 Controller 方法，使其统一返回该对象，提升接口一致性。	简单	代码重构	Java, Spring	后端, 架构优化
16	分析并重写 StudentList.jsx 中的搜索逻辑。解释目前的 debouncedSearch 是如何通过 useEffect 和 setTimeout 实现特性的，并讨论如果移除 clearTimeout 会导致什么后果。	简单	代码理解与分析	React, JavaScript	前端, 性能优化
17	在 frontend/src/main.jsx 的 React Router 配置中，添加一个 Catch-all 路由，当用户访问不存在的路径时，展示一个具有“回到首页”按钮的美化 404 页面。	简单	功能迭代	React Router	前端, 路由
18	修改 frontend/tailwind.config.js，在 extend 中添加一组品牌色 brand: { 500: '#...' }。随后将 StudentList.jsx 中所有蓝色按钮的 bg-blue-600 替换为自定义的品牌色。	简单	功能迭代	Tailwind CSS	前端, 样式系统
19	在 StudentController 中实现一个 /export 接口。使用 OutputStream 将 studentService.getAllStudents() 的结果以 CSV 字符流的形式输出，支持浏览器点击下载。	中等	功能迭代	Java, Spring MVC	后端, 导出功能
20	分析 StudentMapper.xml 中的 findById 标签。目前通过 LEFT JOIN 一次性查出班级名。请尝试将其重构为使用 <association> 标签的嵌套查询方式，并对比两者的执行效率。	简单	代码理解与分析	MyBatis	后端, 持久层
