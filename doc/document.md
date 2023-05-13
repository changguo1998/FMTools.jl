# `JSM2` 使用说明

[toc]

## 程序结构

## 数据类型

### 抽象类型 `PreprocessedData`

### 事件信息 `Event`

`Event` 数据结构包括以下数据
- `time`
- `lat`
- `lon`
- `dep`
- `mag`
- `t0`
- `tag`

```julia
mutable struct Event <: PreprocessedData
    # - event info
    time::DateTime
    lat::Float64
    lon::Float64
    dep::Length
    mag::Float64
    t0::TimePeriod
    tag::String
end
```

### 台站信息 `Station`

### 通道信息 `RecordChannel`

### 震相信息 `Phase`

### 算法设置 `AlgorithmSetting`

### 反演设置 `InverseSetting`

## 目标函数

## 搜索方法

## 附录A 格林函数文件格式

## 附录B 基础数据类型
