sub init()
  m.img = m.top.findNode("img")
  m.timer = createObject("roSGNode","Timer")
  m.timer.duration = 300 ' seconds (5 min)
  m.timer.observeField("fire", "onTick")
  m.top.appendChild(m.timer)

  m.base = "https://christhetech131.github.io/FaithSaver"
  m.category = GetCategory()
  m.index = invalid
  FetchIndex() ' async
end sub

function GetCategory() as string
  reg = CreateObject("roRegistrySection","FaithSaver")
  cat = reg.Read("category")
  if cat = invalid or cat = "" then return "animals"
  return cat
end function

sub FetchIndex()
  url = m.base + "/index.json?t="+str(Asc(Left(CreateObject("roDateTime").AsSeconds().ToStr(),1))) ' cache bust lite
  port = CreateObject("roMessagePort")
  xfer = CreateObject("roUrlTransfer")
  xfer.setMessagePort(port)
  xfer.setUrl(url)
  xfer.AsyncGetToString()
  while true
    msg = wait(0, port)
    if type(msg)="roUrlEvent" then
      if msg.GetResponseCode()=200 then
        m.index = ParseJson(msg.GetString())
        ShowRandom()
        m.timer.control="start"
      end if
      return
    end if
  end while
end sub

sub ShowRandom()
  if m.index=invalid then return
  list = m.index.categories[m.category]
  if list=invalid or list.count()=0 then return
  idx = Rnd(0) * list.count() : idx = int(idx)
  m.nextUrl = m.base + list[idx]
  m.img.uri = m.nextUrl
end sub

sub onTick()
  ShowRandom()
end sub
