"""Seed initial track data with points for testing."""
import asyncio
import sys
import uuid
import math
import random
sys.path.insert(0, ".")

from datetime import datetime, timedelta
from app.database import AsyncSessionLocal, init_db
from app.tracks.models import Track, TrackPoint


# 北京附近爬山路线的大致坐标
ROUTE_LOCATIONS = [
    {"name": "香山", "base_lat": 39.992, "base_lon": 116.185, "elevation_base": 150},
    {"name": "百望山", "base_lat": 40.02, "base_lon": 116.27, "elevation_base": 200},
    {"name": "凤凰岭", "base_lat": 40.08, "base_lon": 116.10, "elevation_base": 300},
    {"name": "妙峰山", "base_lat": 39.95, "base_lon": 116.05, "elevation_base": 400},
    {"name": "白虎涧", "base_lat": 40.12, "base_lon": 116.15, "elevation_base": 180},
]


def generate_track_points(
    base_lat: float,
    base_lon: float,
    elevation_base: float,
    distance_km: float,
    elevation_gain: float,
    point_count: int,
    start_time: datetime,
):
    """Generate realistic track points for a hiking route."""
    points = []

    # 简化的爬山路线：起点 → 上坡 → 山顶 → 下坡 → 终点
    # 模拟一个环形路线

    segment_count = point_count
    time_per_point = (distance_km * 1000 / 4000) * 3600 / point_count  # 约 4km/h

    for i in range(segment_count):
        # 计算进度 (0 到 1)
        progress = i / (segment_count - 1)

        # 上坡阶段 (0-40%), 山顶 (40-50%), 下坡 (50-100%)
        if progress < 0.4:
            # 上坡 - 向东北方向移动，海拔上升
            lat_offset = progress * 0.015
            lon_offset = progress * 0.012
            elevation = elevation_base + (elevation_gain * (progress / 0.4))
        elif progress < 0.5:
            # 山顶区域
            lat_offset = 0.015 + (progress - 0.4) * 0.002
            lon_offset = 0.012 + (progress - 0.4) * 0.003
            elevation = elevation_base + elevation_gain
        else:
            # 下坡 - 向西南方向返回
            lat_offset = 0.017 - (progress - 0.5) * 0.015
            lon_offset = 0.015 - (progress - 0.5) * 0.012
            elevation = elevation_base + elevation_gain - (elevation_gain * ((progress - 0.5) / 0.5))

        # 添加一些随机波动使路线更自然
        lat_offset += random.uniform(-0.0005, 0.0005)
        lon_offset += random.uniform(-0.0005, 0.0005)
        elevation += random.uniform(-10, 10)

        point = TrackPoint(
            id=str(uuid.uuid4()),
            latitude=base_lat + lat_offset,
            longitude=base_lon + lon_offset,
            elevation=round(elevation, 1),
            timestamp=start_time + timedelta(seconds=i * time_per_point),
            speed=random.uniform(0.8, 1.2) if progress < 0.5 else random.uniform(1.0, 1.5),
        )
        points.append(point)

    return points


SAMPLE_TRACKS = [
    {
        "name": "香山晨爬",
        "location": ROUTE_LOCATIONS[0],
        "total_distance": 4200,
        "duration_seconds": 7200,
        "elevation_gain": 450.0,
        "point_count": 84,
    },
    {
        "name": "百望山周末行",
        "location": ROUTE_LOCATIONS[1],
        "total_distance": 3500,
        "duration_seconds": 5400,
        "elevation_gain": 320.0,
        "point_count": 70,
    },
    {
        "name": "凤凰岭挑战",
        "location": ROUTE_LOCATIONS[2],
        "total_distance": 5500,
        "duration_seconds": 10800,
        "elevation_gain": 800.0,
        "point_count": 110,
    },
    {
        "name": "妙峰山古道",
        "location": ROUTE_LOCATIONS[3],
        "total_distance": 6200,
        "duration_seconds": 12600,
        "elevation_gain": 900.0,
        "point_count": 124,
    },
    {
        "name": "白虎涧避暑",
        "location": ROUTE_LOCATIONS[4],
        "total_distance": 2000,
        "duration_seconds": 3600,
        "elevation_gain": 100.0,
        "point_count": 40,
    },
]


async def seed_tracks():
    await init_db()
    async with AsyncSessionLocal() as db:
        for idx, track_data in enumerate(SAMPLE_TRACKS):
            loc = track_data["location"]
            start_time = datetime.now() - timedelta(days=(idx + 1) * 3 + idx, hours=idx + 2)
            end_time = start_time + timedelta(seconds=track_data["duration_seconds"])

            track_id = str(uuid.uuid4())
            track = Track(
                id=track_id,
                user_id="guest_demo",
                name=track_data["name"],
                start_time=start_time,
                end_time=end_time,
                total_distance=track_data["total_distance"],
                duration_seconds=track_data["duration_seconds"],
                elevation_gain=track_data["elevation_gain"],
                elevation_loss=track_data["elevation_gain"] - 20,
                point_count=track_data["point_count"],
                is_public=True,
            )
            db.add(track)

            # 生成轨迹点
            points = generate_track_points(
                loc["base_lat"],
                loc["base_lon"],
                loc["elevation_base"],
                track_data["total_distance"] / 1000,
                track_data["elevation_gain"],
                track_data["point_count"],
                start_time,
            )

            for point in points:
                point.track_id = track_id
                db.add(point)

            print(f"Created track '{track_data['name']}' with {len(points)} points")

        await db.commit()
        print(f"\nSeeded {len(SAMPLE_TRACKS)} tracks with points")


if __name__ == "__main__":
    asyncio.run(seed_tracks())