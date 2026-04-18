from datetime import datetime, timezone
from sqlalchemy import Column, String, Float, Integer, DateTime, Text, ForeignKey, JSON
from sqlalchemy.orm import relationship
from app.database import Base


class Route(Base):
    __tablename__ = "routes"

    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    location = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    distance = Column(Float, default=0.0)  # km
    elevation_gain = Column(Float, default=0.0)  # meters
    max_elevation = Column(Float, default=0.0)
    estimated_duration = Column(Integer, default=0)  # minutes
    difficulty = Column(String, default="moderate")  # easy, moderate, hard, expert
    surface_type = Column(String, default="mixed")  # paved, dirt, rocky, mixed
    tags = Column(JSON, default=list)  # list of tags
    waypoints = Column(JSON, default=list)  # list of waypoint objects
    warnings = Column(JSON, default=list)
    best_seasons = Column(JSON, default=list)
    rating = Column(Float, default=0.0)
    review_count = Column(Integer, default=0)
    image_url = Column(String, nullable=True)
    created_by = Column(String, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    reviews = relationship("Review", back_populates="route", cascade="all, delete-orphan")


class Review(Base):
    __tablename__ = "reviews"

    id = Column(String, primary_key=True)
    route_id = Column(String, ForeignKey("routes.id"), nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    rating = Column(Integer, default=5)  # 1-5
    content = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    route = relationship("Route", back_populates="reviews")
    user = relationship("User")