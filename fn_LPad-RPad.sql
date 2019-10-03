create function dbo.LPad
(
    @string nvarchar(max), -- initial string
    @length int,           -- size of final string
    @pad nvarchar(max)     -- pad string
)
returns varchar(max)
as
begin
    return right(concat(replicate(@pad, @length), @string), @length);
end
go

create function dbo.RPad
(
    @string nvarchar(max), -- initial string
    @length int,           -- size of final string
    @pad nvarchar(max)     -- pad string
)
returns varchar(max)
as
begin
    return left(concat(@string, replicate(@pad, @length)), @length);
end
go
