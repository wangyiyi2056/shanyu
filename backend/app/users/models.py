from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, Table
from sqlalchemy.orm import relationship
from app.database import Base

# Favorites table (many-to-many)
favorites = Table(
    "favorites",
    Base.metadata,
    Column("user_id", String, ForeignKey("users.id"), primary_key=True),
    Column("route_id", String, ForeignKey("routes.id"), primary_key=True),
)


class Achievement(Base):
    __tablename__ = "achievements"

    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    type = Column(String, nullable=False)  # first_hike, distance_10km, etc.
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    icon = Column(String, nullable=True)
    earned_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="achievements")


# Add achievements relationship to User
from app.auth.models import User
User.achievements = relationship("Achievement", back_populates="user", cascade="all, delete-orphan")
User.favorites = relationship("Route", secondary=favorites, back_populates="favorited_by")

# Add favorited_by relationship to Route
from app.routes.models import Route
Route.favorited_by = relationship("User", secondary=favorites, back_populates="favorites")