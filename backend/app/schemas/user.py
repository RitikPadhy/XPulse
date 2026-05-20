from pydantic import BaseModel, ConfigDict, Field


class UserCreate(BaseModel):
    display_name: str = Field(min_length=1, max_length=64)
    avatar: str = "ronin"


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    display_name: str
    avatar: str
    arena: str
    trophies: int
